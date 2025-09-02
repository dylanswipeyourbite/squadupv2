import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as admin from 'npm:firebase-admin';

// Initialize Firebase Admin (assuming service account env var or similar)
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!)),
});

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

    const decodedToken = await admin.auth().verifyIdToken(idToken);
    if (decodedToken.uid !== uid) {
      throw new Error('Invalid token');
    }

    // Create Supabase client with service role key (from environment)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Example: Create user if not exists and return access token
    const { data: user, error } = await supabase.auth.admin.createUser({
      email: email,
      email_confirm: true,
      user_metadata: { display_name: displayName, firebase_uid: uid },
    });

    if (error && error.message !== 'User already registered') throw error;

    // Generate a session or token
    const { data: session } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email: email,
    });  // Or use custom logic

    // Return proper session data
    return new Response(
      JSON.stringify({ session: session }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    );
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
