#!/bin/bash

# Deploy Edge Functions to Supabase
# Usage: ./deploy_functions.sh

echo "Deploying Edge Functions to Supabase..."

# Deploy fetch-messages function
echo "Deploying fetch-messages..."
supabase functions deploy fetch-messages

# Deploy send-message function
echo "Deploying send-message..."
supabase functions deploy send-message

# Deploy other chat functions
echo "Deploying edit-message..."
supabase functions deploy edit-message

echo "Deploying delete-message..."
supabase functions deploy delete-message

echo "Deploying add-reaction..."
supabase functions deploy add-reaction

echo "Deploying remove-reaction..."
supabase functions deploy remove-reaction

echo "Deploying mark-messages-read..."
supabase functions deploy mark-messages-read

echo "Deploying fetch-message..."
supabase functions deploy fetch-message

echo "Edge Functions deployment complete!"
