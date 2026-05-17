# NetherLink

Flutter app for NetherLink (Minecraft relay service).

## Stack
- Flutter / Dart
- Firebase Auth (`firebase_auth`, `AuthService`)
- WebSocket via `web_socket_channel` for real-time messaging and presence
- API: `https://eubackend.netherlink.net` (EU only, hardcoded in `MessageService`)

## Code style
- No comments in code
- No docstrings

## Key files
- `lib/screens/profile_screen.dart` — 4 tabs: PROFILE, FRIENDS, REQUESTS, CHATS
- `lib/screens/chat_screen.dart` — direct messaging UI
- `lib/screens/conversations_screen.dart` — inbox
- `lib/services/message_service.dart` — WebSocket + HTTP for messaging and presence
- `lib/services/auth_service.dart` — Firebase auth wrapper
- `lib/models/user_model.dart` — UserModel, FriendModel, FriendRequest
- `lib/models/message_model.dart` — MessageModel, ConversationModel

## Preferences
- Push changes directly to GitHub (main branch) without asking
- No code comments
- No file delivery unless explicitly requested
