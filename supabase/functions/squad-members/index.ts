import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get the auth token from the request header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Verify the user token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid token')
    }

    // Parse request body
    const { squadId } = await req.json()

    // Validate input
    if (!squadId) {
      throw new Error('Squad ID is required')
    }

    // Check if user is a member of the squad
    const { data: membership, error: memberError } = await supabaseClient
      .from('squad_members')
      .select('id')
      .eq('squad_id', squadId)
      .eq('profile_id', user.id)
      .single()

    if (memberError || !membership) {
      throw new Error('You are not a member of this squad')
    }

    // Get all squad members
    const { data: members, error: fetchError } = await supabaseClient
      .from('squad_members')
      .select(`
        id,
        squad_id,
        profile_id,
        role,
        joined_at,
        total_activities,
        total_distance_km,
        last_activity_at,
        notifications_enabled,
        profiles (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('squad_id', squadId)
      .order('role', { ascending: true })
      .order('joined_at', { ascending: true })

    if (fetchError) {
      console.error('Error fetching members:', fetchError)
      throw new Error('Failed to fetch squad members')
    }

    // Format the response
    const formattedMembers = members?.map(m => ({
      id: m.id,
      squadId: m.squad_id,
      profileId: m.profile_id,
      displayName: m.profiles.display_name,
      avatarUrl: m.profiles.avatar_url,
      role: m.role,
      joinedAt: m.joined_at,
      totalActivities: m.total_activities,
      totalDistanceKm: m.total_distance_km,
      lastActivityAt: m.last_activity_at,
      notificationsEnabled: m.notifications_enabled
    })) || []

    return new Response(
      JSON.stringify({ data: formattedMembers }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Squad members error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
