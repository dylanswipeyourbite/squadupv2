import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// System prompt for the onboarding coach
const SYSTEM_PROMPT = `You are an experienced endurance coach helping a new athlete join SquadUp. You understand the obsessed mindset - the 4:30 AM alarms, checking weather apps 73 times before a long run, and the deep satisfaction of perfectly executed intervals.

IMPORTANT - Your first response should explain WHY you're asking questions:
"I'm here to learn what makes you tick as a runner. Our AI coaches use everything we discuss to give you truly personalized guidance - not generic training plans, but advice that fits YOUR life, YOUR goals, YOUR obsessions. The more honest you are about what drives you, the better I can help you become the runner you want to be."

Your personality:
- Warm but direct - like a coach who's been there
- You get the obsession and speak their language
- Use running/endurance terms naturally
- Keep responses concise but meaningful (2-4 sentences)
- ALWAYS ask a follow-up question to dig deeper

Special directives:
- If user says they want to skip/continue/move on, respond: "I understand - sometimes you just want to dive in! Ready to create your squad?" and allow them to proceed
- Occasionally remind them why you're gathering info: "Our AI coaches will use this to personalize your training" or "This helps me understand how to support your specific journey"
- NEVER mention finding squadmates or matching with other runners - focus only on personalized coaching benefits

Your conversation strategy:
- Start by explaining the purpose, then dive into their story
- When they mention something interesting, probe further
- If they say "marathon", ask which one and what time they're chasing
- If they mention injury, understand the story and recovery
- If they talk about goals, understand the why behind them
- Learn their training philosophy and what makes them tick

Topics to explore thoroughly:
1. Experience level - but go beyond basics (favorite workouts, breakthrough moments)
2. Current training - weekly structure, favorite routes, what works for them
3. Goals - not just what, but why and by when
4. Constraints - injuries, work/life, weather preferences
5. Training philosophy - what they believe about improvement
6. Their running story - what got them hooked?
7. Gear obsessions, nutrition experiments, race rituals
8. What frustrates them most about generic training advice

Guidelines:
- Take your time - this is about building connection
- Acknowledge what they share before asking the next question
- Use their language back to them (if they say "crush", you say "crush")
- Share tiny relatable moments ("oh, the pre-race 3am wake-up...")
- Don't rush to the next topic - exhaust the current one first

Never:
- Rush the conversation or try to wrap up quickly
- Use generic responses - everything should feel personal
- Suggest they need "balance" - embrace the obsession
- Make it feel like a questionnaire

Remember: You're not just collecting data, you're understanding what makes this runner unique so our AI can coach them like they deserve - not with cookie-cutter plans, but with guidance that actually fits their life.`

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { messages, profileId } = await req.json()

    // Initialize OpenAI (you'll need to add your API key to Supabase secrets)
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured')
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          ...messages
        ],
        temperature: 0.8,
        max_tokens: 200,
        presence_penalty: 0.6,
        frequency_penalty: 0.3,
      }),
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`OpenAI API error: ${error}`)
    }

    const data = await response.json()
    const aiResponse = data.choices[0].message.content

    // Extract any structured data from the conversation
    // This is where we'd parse out experience level, goals, etc.
    const extractedData = extractDataFromConversation(messages, aiResponse)
    
    // Update profile if we extracted useful data
    if (extractedData && Object.keys(extractedData).length > 0) {
      await supabase
        .from('profiles')
        .update({ 
          onboarding_data: extractedData,
          updated_at: new Date().toISOString()
        })
        .eq('id', profileId)
    }

    return new Response(
      JSON.stringify({ 
        message: aiResponse,
        extractedData 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Onboarding assistant error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})

// Helper function to extract structured data from conversation
function extractDataFromConversation(messages: any[], latestResponse: string): any {
  const allText = messages.map(m => m.content).join(' ') + ' ' + latestResponse
  const data: any = {}

  // Extract experience level with more nuance
  if (allText.match(/beginner|just start|new to|first time|couch to/i)) {
    data.experienceLevel = 'beginner'
  } else if (allText.match(/boston|qualify|sub[- ]?3|ultra|ironman|elite|competitive/i)) {
    data.experienceLevel = 'advanced'
  } else if (allText.match(/5k|10k|half|years? of|been running/i)) {
    data.experienceLevel = 'intermediate'
  }

  // Extract goals
  const raceMatches = allText.match(/(marathon|ultra|ironman|5k|10k|half marathon|trail|triathlon|spartan)/gi)
  if (raceMatches) {
    data.raceGoals = [...new Set(raceMatches.map(r => r.toLowerCase()))]
  }

  // Extract time goals
  const timeMatches = allText.match(/sub[- ]?(\d+):?(\d+)?|break (\d+):?(\d+)?|under (\d+):?(\d+)?|BQ|PR/i)
  if (timeMatches) {
    data.timeGoals = timeMatches[0]
  }

  // Extract training preferences
  if (allText.match(/morning|dawn|early|4:30|5[ :]?am|sunrise/i)) {
    data.preferredTime = 'morning'
  } else if (allText.match(/evening|night|pm|after work/i)) {
    data.preferredTime = 'evening'
  } else if (allText.match(/lunch|midday|noon/i)) {
    data.preferredTime = 'midday'
  }

  // Extract weekly mileage
  const mileageMatch = allText.match(/(\d+)[- ]?(miles|km|k)[\s]*(per|a|\/)?[\s]*week/i)
  if (mileageMatch) {
    data.weeklyMileage = mileageMatch[1] + ' ' + (mileageMatch[2] || 'miles')
  }

  // Extract injury mentions
  if (allText.match(/injury|injured|hurt|pain|recovery|rehab|PT|physical therapy/i)) {
    data.hasInjuryConcerns = true
  }

  // Extract training style preferences
  if (allText.match(/alone|solo|by myself/i)) {
    data.trainingStyle = 'solo'
  } else if (allText.match(/group|club|team|crew/i)) {
    data.trainingStyle = 'group'
  } else if (allText.match(/both|mix|depends/i)) {
    data.trainingStyle = 'mixed'
  }

  // Extract motivation keywords
  const motivationKeywords = []
  if (allText.match(/compete|competition|racing|win/i)) motivationKeywords.push('competition')
  if (allText.match(/health|fitness|weight|feel good/i)) motivationKeywords.push('health')
  if (allText.match(/community|friends|social/i)) motivationKeywords.push('social')
  if (allText.match(/challenge|push|limits|PR/i)) motivationKeywords.push('challenge')
  if (allText.match(/mental|stress|clarity|therapy/i)) motivationKeywords.push('mental')
  
  if (motivationKeywords.length > 0) {
    data.motivation = motivationKeywords
  }

  return data
}