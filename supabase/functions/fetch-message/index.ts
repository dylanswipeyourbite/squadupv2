import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Get auth token from request
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify user
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { messageId } = await req.json()

    if (!messageId) {
      return new Response(
        JSON.stringify({ error: 'Message ID is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user's profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('id')
      .eq('user_id', user.id)
      .single()

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: 'User profile not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch the message with all related data
    const { data: message, error: messageError } = await supabaseClient
      .from('squad_messages')
      .select(`
        id,
        squad_id,
        profile_id,
        type,
        content,
        metadata,
        reply_to_id,
        edited_at,
        deleted_at,
        created_at,
        profile:profiles!squad_messages_profile_id_fkey (
          id,
          display_name,
          avatar_url
        ),
        reply_to:squad_messages!squad_messages_reply_to_id_fkey (
          id,
          content,
          type,
          profile:profiles!squad_messages_profile_id_fkey (
            id,
            display_name,
            avatar_url
          )
        ),
        reactions:message_reactions (
          id,
          emoji,
          profile_id,
          created_at,
          profile:profiles!message_reactions_profile_id_fkey (
            id,
            display_name,
            avatar_url
          )
        ),
        read_receipts:message_read_receipts (
          profile_id
        )
      `)
      .eq('id', messageId)
      .single()

    if (messageError || !message) {
      return new Response(
        JSON.stringify({ error: 'Message not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if user has access to this message
    const { data: membership, error: membershipError } = await supabaseClient
      .from('squad_members')
      .select('id')
      .eq('squad_id', message.squad_id)
      .eq('profile_id', profile.id)
      .single()

    if (membershipError || !membership) {
      return new Response(
        JSON.stringify({ error: 'Not authorized to view this message' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Transform the response to match our expected format
    const transformedMessage = {
      id: message.id,
      squadId: message.squad_id,
      profileId: message.profile_id,
      type: message.type === 'activity_checkin' ? 'activityCheckin' : message.type,
      content: message.content,
      metadata: message.metadata,
      replyToId: message.reply_to_id,
      editedAt: message.edited_at,
      deletedAt: message.deleted_at,
      createdAt: message.created_at,
      author: message.profile ? {
        id: message.profile.id,
        displayName: message.profile.display_name,
        avatarUrl: message.profile.avatar_url
      } : null,
      replyTo: message.reply_to ? {
        id: message.reply_to.id,
        content: message.reply_to.content,
        type: message.reply_to.type === 'activity_checkin' ? 'activityCheckin' : message.reply_to.type,
        author: message.reply_to.profile ? {
          id: message.reply_to.profile.id,
          displayName: message.reply_to.profile.display_name,
          avatarUrl: message.reply_to.profile.avatar_url
        } : null
      } : null,
      reactions: (message.reactions || []).map(r => ({
        id: r.id,
        emoji: r.emoji,
        profileId: r.profile_id,
        createdAt: r.created_at,
        author: r.profile ? {
          id: r.profile.id,
          displayName: r.profile.display_name,
          avatarUrl: r.profile.avatar_url
        } : null
      })),
      readByProfileIds: (message.read_receipts || []).map(r => r.profile_id)
    }

    return new Response(
      JSON.stringify({ message: transformedMessage }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
