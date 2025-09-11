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
    const { squadId, limit = 50, beforeMessageId } = await req.json()

    if (!squadId) {
      return new Response(
        JSON.stringify({ error: 'Squad ID is required' }),
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

    // Check if user is a member of the squad
    const { data: membership, error: membershipError } = await supabaseClient
      .from('squad_members')
      .select('id')
      .eq('squad_id', squadId)
      .eq('profile_id', profile.id)
      .single()

    if (membershipError || !membership) {
      return new Response(
        JSON.stringify({ error: 'Not a member of this squad' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build query
    let query = supabaseClient
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
        reactions:message_reactions (
          id,
          message_id,
          profile_id,
          emoji,
          created_at
        ),
        read_receipts:message_read_receipts (
          profile_id
        )
      `)
      .eq('squad_id', squadId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(limit)

    // Add pagination
    if (beforeMessageId) {
      // Get the timestamp of the reference message
      const { data: refMessage } = await supabaseClient
        .from('squad_messages')
        .select('created_at')
        .eq('id', beforeMessageId)
        .single()

      if (refMessage) {
        query = query.lt('created_at', refMessage.created_at)
      }
    }

    const { data: messages, error: messagesError } = await query

    if (messagesError) {
      console.error('Error fetching messages:', messagesError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch messages' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Transform data to match expected format
    const transformedMessages = messages?.map(msg => ({
      id: msg.id,
      squad_id: msg.squad_id,
      profile_id: msg.profile_id,
      type: msg.type,
      content: msg.content,
      metadata: msg.metadata,
      reply_to_id: msg.reply_to_id,
      edited_at: msg.edited_at,
      deleted_at: msg.deleted_at,
      created_at: msg.created_at,
      author: msg.profile ? {
        id: msg.profile.id,
        display_name: msg.profile.display_name,
        avatar_url: msg.profile.avatar_url
      } : null,
      reactions: msg.reactions || [],
      read_by_profile_ids: msg.read_receipts?.map((r: any) => r.profile_id) || []
    })) || []

    // Reverse to get chronological order (newest last)
    transformedMessages.reverse()

    return new Response(
      JSON.stringify({ data: transformedMessages }),
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
