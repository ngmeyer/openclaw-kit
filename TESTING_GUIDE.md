# OpenClawKit Native Chat Interface - Testing Guide

## 🚀 Quick Start

### Prerequisites
1. OpenClaw gateway installed and configured
2. Valid API key in `~/.openclaw/openclaw.json`
3. Gateway running: `openclaw gateway start`

### Build & Run
```bash
cd /Users/nealme/clawd/projects/openclaw-kit
open OpenClawKit/OpenClawKit.xcodeproj

# In Xcode: Product > Run (⌘R)
```

---

## 🧪 Test Scenarios

### 1. Basic Message Flow
**Steps:**
1. Complete setup wizard
2. Chat view should appear automatically
3. Type "Hello" in the input field
4. Click send button (or press Cmd+Enter)
5. Watch for typing indicator
6. Verify response streams character-by-character

**Expected:**
- ✅ User message appears immediately in blue bubble
- ✅ Typing indicator shows "Aria" with animated dots
- ✅ Assistant response streams in real-time
- ✅ Typing indicator disappears when complete

---

### 2. Markdown Rendering
**Test Message:**
```
Show me examples of **bold**, *italic*, and `code` formatting.

## Heading Example
- List item 1
- List item 2

```python
def hello_world():
    print("Hello, World!")
```
```

**Expected:**
- ✅ Bold text is **bold**
- ✅ Italic text is *slanted*
- ✅ Inline code has green monospace font
- ✅ Heading is larger and bold
- ✅ List items have bullet points
- ✅ Code block has dark background

---

### 3. Message History Persistence
**Steps:**
1. Send several messages
2. Quit OpenClawKit (⌘Q)
3. Relaunch app
4. Navigate to chat view

**Expected:**
- ✅ All previous messages are restored
- ✅ Conversation continues from last point
- ✅ File saved at: `~/Library/Application Support/OpenClawKit/chat_history.json`

**Verify:**
```bash
cat ~/Library/Application\ Support/OpenClawKit/chat_history.json
```

---

### 4. Auto-Scroll During Streaming
**Steps:**
1. Send a message that generates a long response
   - Example: "Write a 500-word essay about AI"
2. Watch as response streams
3. Verify scroll position

**Expected:**
- ✅ View auto-scrolls to bottom as text appears
- ✅ No manual scrolling needed
- ✅ Smooth animation

---

### 5. Copy Message
**Steps:**
1. Right-click (or Control+Click) on any message
2. Select "Copy" from context menu
3. Paste (⌘V) into TextEdit

**Expected:**
- ✅ Full message content is copied
- ✅ Plain text (no styling)
- ✅ Matches original message exactly

---

### 6. Clear Conversation
**Steps:**
1. Click trash icon in header
2. Confirm "Clear" in alert dialog
3. Verify messages disappear

**Expected:**
- ✅ All messages are removed
- ✅ Welcome message reappears
- ✅ Chat history file is deleted

**Verify:**
```bash
ls ~/Library/Application\ Support/OpenClawKit/chat_history.json
# Should show: No such file or directory
```

---

### 7. Error Handling

#### No Gateway Connection
**Steps:**
1. Stop gateway: `openclaw gateway stop`
2. Try to send a message

**Expected:**
- ✅ Error banner appears at top
- ✅ "Retry" button is shown
- ✅ Connection status shows "Disconnected" (red dot)

#### Network Timeout
**Steps:**
1. Add delay in gateway (if possible)
2. Send message

**Expected:**
- ✅ Request times out after 60 seconds
- ✅ Error message is clear
- ✅ Chat remains usable

#### Empty Message
**Steps:**
1. Try to send empty message
2. Try to send whitespace-only message

**Expected:**
- ✅ Send button is disabled
- ✅ No message is sent

---

## 🎹 Keyboard Shortcuts

### Cmd+Enter (Send Message)
**Steps:**
1. Type message
2. Press Cmd+Enter

**Expected:**
- ✅ Message sends immediately
- ✅ Same as clicking send button

---

## 🐛 Bug Testing

### Edge Cases

#### Very Long Message
**Test:**
Send a message with 1000+ characters

**Expected:**
- ✅ Message bubble expands
- ✅ Scrollable if needed
- ✅ No UI glitches

#### Special Characters
**Test:**
```
Test emojis: 🚀 🤖 💬
Test symbols: < > & " '
Test unicode: 你好 مرحبا
```

**Expected:**
- ✅ All characters render correctly
- ✅ No encoding issues

#### Rapid Messages
**Test:**
Send 10 messages quickly (don't wait for responses)

**Expected:**
- ✅ All messages queue properly
- ✅ Responses stream in order
- ✅ No crashes or hangs

---

## 📊 Performance Testing

### Memory Usage
**Monitor:**
```bash
# While app is running:
ps aux | grep OpenClawKit | grep -v grep
```

**Expected:**
- ✅ < 100MB memory usage with 50 messages
- ✅ No memory leaks over time

### Streaming Speed
**Test:**
Ask for a long response and measure time to first token

**Expected:**
- ✅ < 2 seconds to first character
- ✅ Smooth streaming (30+ chars/sec)

---

## 🔧 Debug Tools

### Enable Logging
Add to `ChatViewModel.swift`:
```swift
print("📤 Sending message: \(text)")
print("📥 Received delta: \(delta)")
```

### Check Gateway Logs
```bash
tail -f ~/.openclaw/logs/gateway.log
```

### Inspect Network Traffic
```bash
# Terminal proxy (optional):
mitmproxy -p 8888
```

---

## ✅ Acceptance Criteria Checklist

- [ ] Messages send and receive correctly
- [ ] SSE streaming works (character-by-character display)
- [ ] Message bubbles styled properly (user blue, assistant purple)
- [ ] History persists across app restarts
- [ ] No crashes on error states (graceful degradation)
- [ ] Markdown renders correctly (bold, italic, code, lists)
- [ ] Auto-scroll follows streaming content
- [ ] Copy to clipboard works
- [ ] Clear conversation works
- [ ] Connection status indicator accurate
- [ ] Typing indicator animates correctly
- [ ] Error banner shows on failures
- [ ] Retry button functional
- [ ] Keyboard shortcut (Cmd+Enter) works

---

## 🚨 Known Issues & Workarounds

### Issue: Cmd+Enter Not Working
**Workaround:** Click send button
**Fix:** Verify keyboard event handling in ChatInputView

### Issue: Markdown Links Not Clickable
**Status:** Planned for Phase 2
**Workaround:** Copy & paste URL manually

---

## 📝 Report Template

```markdown
## Test Report: [Test Name]

**Date:** YYYY-MM-DD
**Tester:** [Your Name]
**Build:** [Version/Commit]

### Results
- [ ] Passed
- [ ] Failed
- [ ] Blocked

### Notes
[Describe any issues or observations]

### Screenshots
[Attach if applicable]
```

---

## 🎯 Next Steps After Testing

1. **File bugs** for any failures in GitHub Issues
2. **Update documentation** with any clarifications needed
3. **Test on different macOS versions** (if available)
4. **Gather user feedback** from early adopters
5. **Measure performance** in real-world scenarios

---

**Last Updated:** February 10, 2026  
**Version:** 1.0.0 (Initial Release)
