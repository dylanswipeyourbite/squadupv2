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
    const { inviteCode } = await req.json()

    // Validate input
    if (!inviteCode || inviteCode.length !== 9) {
      throw new Error('Invalid invite code')
    }

    // Find the squad by invite code
    const { data: squad, error: squadError } = await supabaseClient
      .from('squads')
      .select('*')
      .eq('invite_code', inviteCode.toUpperCase())
      .single()

    if (squadError || !squad) {
      throw new Error('Invalid invite code')
    }

    // Get user profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('id, display_name, avatar_url')
      .eq('user_id', user.id)
      .single()

    if (profileError || !profile) {
      throw new Error('User profile not found')
    }

    // Check if user is already a member
    const { data: existingMember } = await supabaseClient
      .from('squad_members')
      .select('id')
      .eq('squad_id', squad.id)
      .eq('profile_id', profile.id)
      .single()

    if (existingMember) {
      throw new Error('You are already a member of this squad')
    }

    // Add user as member
    const now = new Date().toISOString()
    const { error: memberError } = await supabaseClient
      .from('squad_members')
      .insert({
        squad_id: squad.id,
        profile_id: profile.id,
        role: 'member',
        joined_at: now,
        total_activities: 0,
        total_distance_km: 0,
        notifications_enabled: true
      })

    if (memberError) {
      console.error('Member insertion error:', memberError)
      throw new Error('Failed to join squad')
    }

    // Update squad member count
    const { error: updateError } = await supabaseClient
      .from('squads')
      .update({ 
        member_count: squad.member_count + 1,
        updated_at: now
      })
      .eq('id', squad.id)

    if (updateError) {
      // Try to rollback member insertion
      await supabaseClient
        .from('squad_members')
        .delete()
        .eq('squad_id', squad.id)
        .eq('profile_id', profile.id)
      
      throw new Error('Failed to update squad')
    }

    // Return the joined squad with formatted response
    const response = {
      squad: {
        id: squad.id,
        name: squad.name,
        description: squad.description,
        inviteCode: squad.invite_code,
        visibility: squad.visibility,
        maxMembers: squad.max_members,
        memberCount: squad.member_count + 1,
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
    console.error('Squad join error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
