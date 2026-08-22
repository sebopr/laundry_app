/// Tracks which chat conversation (by the other participant's uid) is
/// currently open on screen, so a foreground push for that exact
/// conversation can be suppressed — the message is already visible live in
/// the open chat, so popping a notification for it is redundant.
class ActiveChatTracker {
  ActiveChatTracker._();

  static String? currentPeerId;
}
