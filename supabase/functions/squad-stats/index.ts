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
    const { data: membership } = await supabaseClient
      .from('squad_members')
      .select('id')
      .eq('squad_id', squadId)
      .eq('profile_id', user.id)
      .single()

    if (!membership) {
      throw new Error('You are not a member of this squad')
    }

    // Get squad basic stats
    const { data: squad } = await supabaseClient
      .from('squads')
      .select('total_distance_km, total_activities')
      .eq('id', squadId)
      .single()

    // Get weekly stats
    const oneWeekAgo = new Date()
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)

    // Get weekly distance from activities joined to this squad
    const { data: weeklyActivities } = await supabaseClient
      .from('activity_checkins')
      .select(`
        activities (
          distance_km
        )
      `)
      .eq('squad_id', squadId)
      .gte('created_at', oneWeekAgo.toISOString())

    const weeklyDistance = weeklyActivities?.reduce((sum, checkin) => {
      return sum + (checkin.activities?.distance_km || 0)
    }, 0) || 0

    // Get active members (those who have logged activity in last 7 days)
    const { data: activeMembers } = await supabaseClient
      .from('squad_members')
      .select('profile_id')
      .eq('squad_id', squadId)
      .gte('last_activity_at', oneWeekAgo.toISOString())

    const stats = {
      totalDistance: Math.round(squad?.total_distance_km || 0),
      totalActivities: squad?.total_activities || 0,
      weeklyDistance: Math.round(weeklyDistance),
      activeMembers: activeMembers?.length || 0
    }

    return new Response(
      JSON.stringify({ stats }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Squad stats error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
