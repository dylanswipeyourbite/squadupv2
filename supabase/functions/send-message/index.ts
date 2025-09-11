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
    const { squadId, type, content, metadata, replyToId } = await req.json()

    if (!squadId || !type) {
      return new Response(
        JSON.stringify({ error: 'Squad ID and message type are required' }),
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

    // Validate message type
    const validTypes = ['text', 'activity_checkin', 'image', 'voice', 'video', 'poll']
    const messageType = type === 'activityCheckin' ? 'activity_checkin' : type
    
    if (!validTypes.includes(messageType)) {
      return new Response(
        JSON.stringify({ error: 'Invalid message type' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Insert message
    const { data: message, error: insertError } = await supabaseClient
      .from('squad_messages')
      .insert({
        squad_id: squadId,
        profile_id: profile.id,
        type: messageType,
        content: content || null,
        metadata: metadata || {},
        reply_to_id: replyToId || null,
      })
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
        )
      `)
      .single()

    if (insertError) {
      console.error('Error inserting message:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to send message' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Transform response
    const transformedMessage = {
      id: message.id,
      squad_id: message.squad_id,
      profile_id: message.profile_id,
      type: message.type === 'activity_checkin' ? 'activityCheckin' : message.type,
      content: message.content,
      metadata: message.metadata,
      reply_to_id: message.reply_to_id,
      edited_at: message.edited_at,
      deleted_at: message.deleted_at,
      created_at: message.created_at,
      author: message.profile ? {
        id: message.profile.id,
        display_name: message.profile.display_name,
        avatar_url: message.profile.avatar_url
      } : null,
      reactions: [],
      read_by_profile_ids: []
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
