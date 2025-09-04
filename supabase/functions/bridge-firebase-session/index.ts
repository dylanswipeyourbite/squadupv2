import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { idToken, uid, email, displayName } = await req.json()

    // Create Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      }
    })

    // Check if profile exists
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('firebase_uid', uid)
      .single();

    let profileId;

    if (!existingProfile) {
      // Create profile if it doesn't exist
      const { data: newProfile, error: profileError } = await supabase
        .from('profiles')
        .insert({
          firebase_uid: uid,
          email: email,
          display_name: displayName || email.split('@')[0],
        })
        .select()
        .single();

      if (profileError) throw profileError;
      profileId = newProfile.id;
    } else {
      profileId = existingProfile.id;
      
      // Update last seen
      await supabase
        .from('profiles')
        .update({ last_seen_at: new Date().toISOString() })
        .eq('id', profileId);
    }

    // For now, return a simple session object
    // In production, you would create a proper JWT
    const session = {
      access_token: `dummy_token_${uid}`,
      token_type: 'bearer',
      expires_in: 60 * 60 * 24 * 7,
      refresh_token: '',
      user: {
        id: uid,
        email: email,
        app_metadata: {
          provider: 'firebase',
        },
        user_metadata: {
          profile_id: profileId,
          display_name: displayName,
        },
      }
    };

    // Return session data
    return new Response(
      JSON.stringify({ session, profile_id: profileId }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    );
  } catch (error) {
    console.error('Bridge session error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})