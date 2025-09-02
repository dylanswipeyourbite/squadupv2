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

    // TODO: Verify the Firebase ID token with Firebase Admin SDK
    // For now, we'll trust the token (in production, you MUST verify it)
    
    // Create Supabase client with service role key (from environment)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Check if user already exists in Supabase
    const { data: existingUser, error: userCheckError } = await supabase
      .from('profiles')
      .select('id')
      .eq('firebase_uid', uid)
      .single()

    if (!existingUser && !userCheckError) {
      // Create user profile if it doesn't exist
      const { error: insertError } = await supabase
        .from('profiles')
        .insert({
          firebase_uid: uid,
          email: email,
          display_name: displayName,
          created_at: new Date().toISOString(),
        })

      if (insertError) {
        throw new Error(`Failed to create user profile: ${insertError.message}`)
      }
    }

    // Generate a custom session for the user
    // In production, you'd want to create a proper JWT session
    // For now, we'll return a success response
    const sessionData = {
      session: {
        user: {
          id: uid,
          email: email,
          app_metadata: { provider: 'firebase' },
          user_metadata: { display_name: displayName },
        },
        access_token: 'firebase-bridged-token', // This should be a real JWT
        refresh_token: 'firebase-bridged-refresh', // This should be a real refresh token
        expires_at: new Date(Date.now() + 3600000).toISOString(), // 1 hour from now
      }
    }

    return new Response(
      JSON.stringify(sessionData),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
