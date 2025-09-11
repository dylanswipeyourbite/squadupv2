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

    // Get user's profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('id')
      .eq('user_id', user.id)
      .single()

    if (profileError || !profile) {
      throw new Error('User profile not found')
    }

    // Get all squads the user is a member of
    const { data: memberships, error: memberError } = await supabaseClient
      .from('squad_members')
      .select(`
        squad_id,
        role,
        squads (
          id,
          name,
          description,
          invite_code,
          visibility,
          max_members,
          member_count,
          avatar_url,
          theme_color,
          expert_names,
          total_distance_km,
          total_activities,
          created_at,
          updated_at
        )
      `)
      .eq('profile_id', profile.id)

    if (memberError) {
      console.error('Error fetching memberships:', memberError)
      throw new Error('Failed to fetch squads')
    }

    // Format the response
    const squads = memberships?.map(m => ({
      id: m.squads.id,
      name: m.squads.name,
      description: m.squads.description,
      inviteCode: m.squads.invite_code,
      visibility: m.squads.visibility,
      maxMembers: m.squads.max_members,
      memberCount: m.squads.member_count,
      avatarUrl: m.squads.avatar_url,
      themeColor: m.squads.theme_color,
      expertNames: m.squads.expert_names,
      totalDistanceKm: m.squads.total_distance_km,
      totalActivities: m.squads.total_activities,
      createdAt: m.squads.created_at,
      updatedAt: m.squads.updated_at
    })) || []

    return new Response(
      JSON.stringify({ data: squads }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Squad list error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
