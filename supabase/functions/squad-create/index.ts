import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Generate a random invite code
function generateInviteCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 9; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role key for admin operations
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
    const { name, description, avatarUrl } = await req.json()

    // Validate input
    if (!name || name.trim().length < 3) {
      throw new Error('Squad name must be at least 3 characters')
    }
    if (name.trim().length > 30) {
      throw new Error('Squad name must be less than 30 characters')
    }

    // Generate unique invite code
    let inviteCode = generateInviteCode()
    let attempts = 0
    while (attempts < 10) {
      const { data: existing } = await supabaseClient
        .from('squads')
        .select('id')
        .eq('invite_code', inviteCode)
        .single()
      
      if (!existing) break
      
      inviteCode = generateInviteCode()
      attempts++
    }

    if (attempts >= 10) {
      throw new Error('Failed to generate unique invite code')
    }

    // Start a transaction
    const now = new Date().toISOString()

    // Create the squad
    const { data: squad, error: squadError } = await supabaseClient
      .from('squads')
      .insert({
        name: name.trim(),
        description: description?.trim() || null,
        invite_code: inviteCode,
        max_members: null, // No limit
        member_count: 1,
        avatar_url: avatarUrl || null,
        visibility: 'private',
        expert_names: {
          sage: 'Sage',
          alex: 'Alex',
          nova: 'Nova',
          aria: 'Aria',
          pace: 'Pace',
          koa: 'Koa'
        },
        total_distance_km: 0,
        total_activities: 0,
        created_at: now,
        updated_at: now
      })
      .select()
      .single()

    if (squadError) {
      console.error('Squad creation error:', squadError)
      throw new Error('Failed to create squad')
    }

    // Get user profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('id, display_name, avatar_url')
      .eq('user_id', user.id)
      .single()

    if (profileError || !profile) {
      // Rollback squad creation
      await supabaseClient.from('squads').delete().eq('id', squad.id)
      throw new Error('User profile not found')
    }

    // Add user as captain
    const { error: memberError } = await supabaseClient
      .from('squad_members')
      .insert({
        squad_id: squad.id,
        profile_id: profile.id,
        role: 'captain',
        joined_at: now,
        total_activities: 0,
        total_distance_km: 0,
        notifications_enabled: true
      })

    if (memberError) {
      // Rollback squad creation
      await supabaseClient.from('squads').delete().eq('id', squad.id)
      console.error('Member creation error:', memberError)
      throw new Error('Failed to add captain to squad')
    }

    // Return the created squad with formatted response
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
    console.error('Squad creation error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
