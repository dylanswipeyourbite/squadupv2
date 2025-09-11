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
    const { data: member, error: memberError } = await supabaseClient
      .from('squad_members')
      .select('id')
      .eq('squad_id', squadId)
      .eq('profile_id', user.id)
      .single()

    if (memberError || !member) {
      throw new Error('You are not a member of this squad')
    }

    // Get the squad
    const { data: squad, error: squadError } = await supabaseClient
      .from('squads')
      .select('*')
      .eq('id', squadId)
      .single()

    if (squadError || !squad) {
      throw new Error('Squad not found')
    }

    // Return the squad with formatted response
    const response = {
      squad: {
        id: squad.id,
        name: squad.name,
        description: squad.description,
        inviteCode: squad.invite_code,
        visibility: squad.visibility,
        maxMembers: squad.max_members,
        memberCount: squad.member_count,
        avatarUrl: squad.avatar_url,
        themeColor: squad.theme_color,
        expertNames: squad.expert_names,
        totalDistanceKm: squad.total_distance_km,
        totalActivities: squad.total_activities,
        createdAt: squad.created_at,
        updatedAt: squad.updated_at
      }
    }

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Squad get error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
