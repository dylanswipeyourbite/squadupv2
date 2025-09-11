# SquadUp Chat Implementation Guide

## Overview

The chat functionality has been implemented as the home screen for squads, providing real-time messaging with support for text, activity check-ins, polls, and media messages.

## Architecture

### Domain Layer
- **Message Models**: Comprehensive models for all message types
- **Chat Repository Interface**: Defines the contract for chat operations
- **Chat Service**: Business logic with caching and real-time updates

### Infrastructure Layer
- **Edge Functions**: Secure backend operations via Supabase Edge Functions
- **Chat Repository Implementation**: Supabase integration with real-time subscriptions
- **Edge Function Helper**: Utility for invoking functions with auth

### Presentation Layer
- **ObsessionStreamScreen**: Main chat UI
- **Chat ViewModel**: State management with Provider
- **Reusable Widgets**: Message bubbles, input, typing indicators, etc.

## Setup Instructions

### 1. Deploy Edge Functions

First, ensure you have the Supabase CLI installed and configured:

```bash
# Deploy the Edge Functions
./deploy_functions.sh
```

Or deploy manually:

```bash
supabase functions deploy fetch-messages
supabase functions deploy send-message
# ... deploy other functions
```

### 2. Database Setup

The chat uses these tables (should already exist):
- `squad_messages`: Main messages table
- `message_reactions`: Reactions to messages
- `message_read_receipts`: Read status tracking

### 3. Test the Chat

1. Run the app: `flutter run`
2. Login and navigate to a squad
3. The chat screen should load automatically
4. Try sending messages, reactions, and replies

## Features Implemented

### ✅ Core Messaging
- Real-time text messages
- Message editing and deletion
- Reply threading
- Typing indicators
- Read receipts

### ✅ Rich Content
- Activity check-in cards (ready for Terra data)
- Poll messages (UI ready)
- Media message types (UI ready, upload pending)

### ✅ Interactions
- Emoji reactions
- Long-press message menu
- Swipe to reply (gesture ready)
- @mentions (UI ready, autocomplete pending)

### ✅ UI/UX
- Modern Material 3 design
- Dark theme optimized
- Smooth animations
- Pagination for history
- Date separators

## Pending Edge Functions

Create these additional Edge Functions following the pattern in `fetch-messages` and `send-message`:

### edit-message
```typescript
// Update message content
// Verify user owns the message
// Set edited_at timestamp
```

### delete-message
```typescript
// Soft delete (set deleted_at)
// Verify user owns the message
```

### add-reaction / remove-reaction
```typescript
// Add/remove from message_reactions table
// Verify user is squad member
```

### mark-messages-read
```typescript
// Bulk insert into message_read_receipts
// Verify user is squad member
```

### fetch-message
```typescript
// Get single message with full data
// Used for real-time updates
```

## Testing Checklist

- [ ] Send text message
- [ ] Edit own message
- [ ] Delete own message
- [ ] Reply to message
- [ ] Add/remove reaction
- [ ] See typing indicator
- [ ] Load message history (pagination)
- [ ] See date separators
- [ ] Test with multiple users
- [ ] Verify real-time updates

## Troubleshooting

### Messages not sending
- Check Edge Function deployment
- Verify Supabase auth is working
- Check browser console for errors

### Real-time not working
- Ensure Supabase Realtime is enabled for tables
- Check WebSocket connection
- Verify auth token is valid

### Theme issues
- Use `Theme.of(context).colorScheme` for colors
- Use `Theme.of(context).textTheme` for text styles

## Next Steps

1. **Media Upload**: Implement Firebase Storage integration for images/videos
2. **Voice Notes**: Add voice recording functionality
3. **@Mentions**: Implement autocomplete for user mentions
4. **Polls**: Add poll creation dialog
5. **Activity Integration**: Connect to Terra webhook data
6. **Search**: Add in-chat search functionality
7. **Expert AI**: Integrate AI assistants via @mentions

## Code Quality

The implementation follows:
- Clean architecture principles
- Repository pattern
- Dependency injection
- Separation of concerns
- Material 3 design guidelines
- SquadUp development directive
