# Chat Screen Improvements Plan

## Overview

This document outlines identified gaps, issues, and improvements for the Semantic Butler chat screen. Issues are categorized by severity and priority for implementation.

---

## Table of Contents

1. [Critical Issues](#critical-issues)
2. [High Priority](#high-priority)
3. [Medium Priority](#medium-priority)
4. [Low Priority](#low-priority)
5. [Feature Enhancements](#feature-enhancements)
6. [Technical Debt](#technical-debt)

---

## Critical Issues

These issues should be addressed immediately as they affect core functionality or user experience.

### C1. Edit Window Logic Duplication

**Location:** `lib/models/chat/chat_message.dart:52-56`, `lib/widgets/chat/message_actions_menu.dart:36-40`

**Problem:** The 5-minute edit window is hardcoded in two separate places, creating a maintenance burden and potential for inconsistency.

```dart
// ChatMessage.canEdit
const editWindow = Duration(minutes: 5);

// MessageActionsMenu.canEdit
const editWindow = Duration(minutes: 5);
```

**Solution:** Create a centralized constant and move the logic to a single location.

**Files to modify:**
- `lib/models/chat/chat_message.dart`
- `lib/widgets/chat/message_actions_menu.dart`
- `lib/utils/chat_constants.dart` (new file)

---

### C2. Error Dismiss Not Implemented

**Location:** `lib/screens/chat_screen.dart:821-823`

**Problem:** The `onDismiss` callback for error messages is empty, leaving users unable to dismiss error messages.

```dart
onDismiss: () {
  // This is tricky if we don't have local messages
  // For now, let's just ignore dismiss or handle in provider
},
```

**Solution:** Implement dismiss functionality in the provider to remove or hide error messages.

**Files to modify:**
- `lib/providers/chat_history_provider.dart`
- `lib/screens/chat_screen.dart`
- `lib/widgets/chat/error_message_bubble.dart`

---

### C3. Streaming State Not Reset on Error

**Location:** `lib/screens/chat_screen.dart:556`, `lib/screens/chat_screen.dart:557-585`

**Problem:** The `_isSending` flag is only reset after successful stream completion. If an error occurs mid-stream, the flag may remain `true`, blocking further messages.

**Solution:** Ensure `_isSending` is reset in all code paths, including error handlers.

**Files to modify:**
- `lib/screens/chat_screen.dart`

---

## High Priority

These issues significantly impact user experience but don't completely block functionality.

### H1. Add Typing Indicator to Chat Screen

**Location:** `lib/widgets/chat/typing_indicator.dart`

**Problem:** The `TypingIndicator` widget exists but is never used in the chat screen. Users only see "Thinking..." in the app bar.

**Solution:** Replace or supplement the app bar status with the animated typing indicator at the bottom of the message list.

**Files to modify:**
- `lib/screens/chat_screen.dart`
- `lib/widgets/chat/typing_indicator.dart`

---

### H2. Welcome Screen Logic Fix

**Location:** `lib/screens/chat_screen.dart:782-785`

**Problem:** The welcome screen shows when `currentConversationId == null`, but a new conversation with messages should not show the welcome screen.

```dart
if (messages.isEmpty &&
    state.currentConversationId == null) {
  return _buildWelcome(context);
}
```

**Solution:** Show welcome only when there are truly no messages in the current context.

**Files to modify:**
- `lib/screens/chat_screen.dart`

---

### H3. Scroll-to-Bottom Button

**Problem:** In long conversations, when users scroll up to read history, there's no quick way to return to the latest messages.

**Solution:** Add a floating action button that appears when user scrolls up from bottom, allowing quick return to newest messages.

**Files to create:**
- `lib/widgets/chat/scroll_to_bottom_button.dart`

**Files to modify:**
- `lib/screens/chat_screen.dart`

---

### H4. Reply Content Preview

**Location:** `lib/widgets/chat/chat_message_bubble.dart:550-577`

**Problem:** The reply indicator shows generic text "Replying to a message" instead of the actual content being replied to.

```dart
Text('Replying to a message')
```

**Solution:** Display actual preview of the message being replied to, with truncation if needed.

**Files to modify:**
- `lib/widgets/chat/chat_message_bubble.dart`
- `lib/models/chat/chat_message.dart`

---

### H5. Network Error Detection

**Problem:** No detection or warning when the user is offline. Messages fail silently or with generic errors.

**Solution:** Add connectivity check before sending and show appropriate error messages for offline state.

**Files to create:**
- `lib/utils/connectivity_helper.dart`

**Files to modify:**
- `lib/screens/chat_screen.dart`
- `lib/models/chat/chat_error.dart`

---

## Medium Priority

These issues improve user experience but aren't critical.

### M1. Conversation Rename

**Problem:** Users cannot rename conversations. Titles are auto-generated only from the first message.

**Solution:** Add edit button to conversation titles in sidebar with a dialog for renaming.

**Files to modify:**
- `lib/widgets/chat_history_sidebar.dart`
- `lib/providers/chat_history_provider.dart`
- `lib/services/chat_storage_service.dart`

---

### M2. Message Search Within Conversation

**Problem:** For long conversations, there's no way to find specific messages.

**Solution:** Add search functionality that filters messages in the current conversation.

**Files to create:**
- `lib/widgets/chat/in_chat_search.dart`

**Files to modify:**
- `lib/screens/chat_screen.dart`
- `lib/widgets/chat/chat_app_bar.dart`

---

### M3. Conversation Export

**Problem:** Individual messages can be shared, but entire conversations cannot be exported.

**Solution:** Add export functionality supporting formats like Markdown, PDF, and plain text.

**Files to create:**
- `lib/services/conversation_export_service.dart`

**Files to modify:**
- `lib/widgets/chat_history_sidebar.dart`
- `lib/screens/chat_screen.dart`

---

### M4. Attachment Validation

**Problem:** File attachments have no size limits shown, no progress indicators, and limited type validation.

**Solution:** Add file size limits, type validation, and upload progress tracking.

**Files to create:**
- `lib/utils/file_validation.dart`

**Files to modify:**
- `lib/screens/chat_screen.dart`
- `lib/widgets/chat/chat_input_area.dart`
- `lib/widgets/chat/attached_file_chip.dart`

---

### M5. Draft Saving

**Problem:** If user navigates away mid-composition, the draft is lost.

**Solution:** Auto-save drafts to local storage and restore when returning to chat.

**Files to create:**
- `lib/services/draft_service.dart`

**Files to modify:**
- `lib/screens/chat_screen.dart`
- `lib/widgets/chat/chat_input_area.dart`

---

### M6. Quick Actions Dismissible

**Location:** `lib/widgets/chat/chat_input_area.dart:88-89`

**Problem:** Quick action chips always take up space with no way to dismiss them.

**Solution:** Add collapse/expand toggle for quick actions section.

**Files to modify:**
- `lib/widgets/chat/chat_input_area.dart`
- `lib/widgets/chat/quick_action_chips.dart`

---

## Low Priority

Nice-to-have improvements that can be addressed later.

### L1. Message Reactions

**Problem:** No way to react to messages with emojis.

**Solution:** Add emoji reaction picker and display reactions on messages.

---

### L2. Message Bookmarks/Stars

**Problem:** No way to mark important messages for quick reference.

**Solution:** Add star/bookmark functionality with filter to show only starred messages.

---

### L3. Voice Input

**Problem:** No dictation/voice input option.

**Solution:** Add microphone button with speech-to-text integration.

---

### L4. Conversation Pinning

**Problem:** No way to pin important conversations to top of list.

**Solution:** Add pin functionality with visual indicator and sorted display.

---

### L5. Font Size Control

**Problem:** Users cannot adjust chat font size.

**Solution:** Add font size slider in settings that applies to chat messages.

---

## Feature Enhancements

Potential new features for future consideration.

### F1. Message Branching/Threading

**Description:** Create threaded conversations instead of flat reply structure.

**Complexity:** High - requires data model changes

---

### F2. Rich Text Editor

**Description:** WYSIWYG formatting for user messages (bold, italic, lists).

**Complexity:** Medium

---

### F3. Message Forwarding

**Description:** Forward messages to other conversations.

**Complexity:** Low

---

### F4. @Mentions

**Description:** Mention system for getting attention (in multi-user context).

**Complexity:** Medium (requires multi-user support first)

---

## Technical Debt

Code quality and architecture improvements.

### T1. Extract Hard-coded Constants

**Locations:** Multiple files

**Problem:** Magic numbers scattered throughout:
- Edit window: 5 minutes
- Debounce delay: 75ms
- Page size: 20 messages
- New message animation threshold: 5 seconds

**Solution:** Create centralized configuration/constants.

**Files to create:**
- `lib/utils/chat_constants.dart`

---

### T2. Accessibility Improvements

**Problem:** Missing semantic labels, no keyboard navigation for message actions.

**Solution:**
- Add `Semantics` widgets to all interactive elements
- Implement keyboard shortcuts for common actions
- Ensure proper focus management
- Add screen reader announcements for streaming updates

---

### T3. Message Virtualization

**Location:** `lib/screens/chat_screen.dart:790-839`

**Problem:** For extremely long conversations, even `ListView.builder` may become slow with complex message widgets.

**Solution:** Consider more aggressive virtualization or lazy rendering for off-screen messages.

---

### T4. Background Pattern Checking Optimization

**Location:** `lib/widgets/chat/chat_message_bubble.dart:56-73`

**Problem:** `_checkPatterns` runs on every `didUpdateWidget`, potentially causing redundant background isolates.

**Solution:** Add debouncing or cache results to prevent redundant checks.

---

### T5. Error Handling Expansion

**Location:** `lib/models/chat/chat_error.dart`

**Problem:** Missing specific error types for:
- Rate limiting (429)
- Invalid API key
- Stream interruption
- File attachment errors

**Solution:** Expand `ChatError` types with specific handling for each case.

---

## Implementation Order

### Phase 1: Critical Fixes (Week 1)
1. [x] C1: Edit window logic centralization
2. [x] C2: Error dismiss implementation
3. [x] C3: Streaming state cleanup

### Phase 2: UX Improvements (Week 2)
1. H1: Typing indicator
2. H2: Welcome screen fix
3. H3: Scroll-to-bottom button
4. H4: Reply content preview

### Phase 3: Visual Refactor (Immediate Request)
1. **Message Bubble Architecture**: Refactor `ChatMessageBubble` to follow standard chat conventions:
   - User messages: Aligned right, distinct color (Primary), "speech bubble" shape (rounded corners with one sharp corner).
   - Assistant messages: Aligned left, neutral background, avatar on the left.
2. **Layout & Spacing**:
   - Limit bubble width to 80% of the screen (instead of fixed 600px) for better responsiveness.
   - Improve vertical rhythm between messages.
3. **Metadata Polish**: Clean up timestamps and "edited" badges to be less obtrusive.
4. **Animation Tuning**: Remove sluggish opacity fades for a snappier feel.

### Phase 4: Core Features (Week 3-4)
1. H5: Network error detection
2. M1: Conversation rename
3. M2: In-conversation search
4. M6: Dismissible quick actions

### Phase 5: Polish (Week 5+)
1. M3: Conversation export
2. M4: Attachment validation
3. M5: Draft saving
4. Technical debt items

---

## Testing Checklist

After implementing each improvement, verify:

- [ ] Feature works as expected in all scenarios
- [ ] Edge cases are handled (empty states, errors, etc.)
- [ ] UI is responsive (no jank)
- [ ] Accessibility requirements met
- [ ] Works on all target platforms (macOS, Windows, etc.)
- [ ] No regressions in existing functionality

---

## Related Files

### Core Chat Files
- `lib/screens/chat_screen.dart` - Main chat screen
- `lib/widgets/chat/chat_input_area.dart` - Input field and attachments
- `lib/widgets/chat/chat_message_bubble.dart` - Message display
- `lib/widgets/chat/message_actions_menu.dart` - Message actions
- `lib/models/chat/chat_message.dart` - Message model
- `lib/providers/chat_history_provider.dart` - State management

### Supporting Files
- `lib/services/chat_storage_service.dart` - Database operations
- `lib/utils/stream_debouncer.dart` - Streaming utilities
- `lib/widgets/chat/error_message_bubble.dart` - Error display
- `lib/widgets/markdown/markdown_body.dart` - Markdown rendering
