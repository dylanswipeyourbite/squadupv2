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

    // Check if user is a member and get their role
    const { data: member, error: memberError } = await supabaseClient
      .from('squad_members')
      .select('id, role')
      .eq('squad_id', squadId)
      .eq('profile_id', user.id)
      .single()

    if (memberError || !member) {
      throw new Error('You are not a member of this squad')
    }

    // Check if user is captain
    if (member.role === 'captain') {
      // Count remaining members
      const { count } = await supabaseClient
        .from('squad_members')
        .select('*', { count: 'exact', head: true })
        .eq('squad_id', squadId)

      if (count && count > 1) {
        throw new Error('Captain cannot leave the squad while other members exist. Delete the squad instead.')
      }
    }

    // Remove member from squad
    const { error: deleteError } = await supabaseClient
      .from('squad_members')
      .delete()
      .eq('squad_id', squadId)
      .eq('profile_id', user.id)

    if (deleteError) {
      console.error('Error removing member:', deleteError)
      throw new Error('Failed to leave squad')
    }

    // Update squad member count
    const { data: squad } = await supabaseClient
      .from('squads')
      .select('member_count')
      .eq('id', squadId)
      .single()

    if (squad) {
      await supabaseClient
        .from('squads')
        .update({ 
          member_count: squad.member_count - 1,
          updated_at: new Date().toISOString()
        })
        .eq('id', squadId)
    }

    return new Response(
      JSON.stringify({ success: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Squad leave error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
