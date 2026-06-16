import 'package:flutter/foundation.dart';

/// Arguments passed when a screen wants the shell to switch to the MCQ
/// tab and pre-fill the subject/topic.
class McqRequest {
  final String? subject;
  final String? topic;
  const McqRequest({this.subject, this.topic});
}

/// Top-level navigation controller for the main app shell.
///
/// Two responsibilities:
///  1. Holds the index of the currently visible bottom-nav tab. Tapping a
///     tab in the shell updates this index; the shell's IndexedStack
///     reacts. Tapping a tab does NOT push a new route — the system back
///     button must pop a sub-page (e.g. Profile), not a tab.
///  2. Lets any widget inside any tab request that the shell switch to a
///     specific tab and pass arguments (e.g. TopicRow → switch to MCQ tab
///     and pre-fill subject/topic). The target tab reads the pending
///     request, consumes it, and renders accordingly.
class NavigationController extends ChangeNotifier {
  int _tabIndex = 0;
  McqRequest? _pendingMcq;

  int get tabIndex => _tabIndex;
  McqRequest? get pendingMcq => _pendingMcq;

  void switchTo(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  /// Request the MCQ tab to open with [subject] and [topic] pre-filled.
  /// The MCQ setup screen consumes the request once it has applied it.
  void requestMcq({String? subject, String? topic}) {
    _pendingMcq = McqRequest(subject: subject, topic: topic);
    _tabIndex = 2; // MCQ tab index in the shell.
    notifyListeners();
  }

  void consumeMcqRequest() {
    if (_pendingMcq == null) return;
    _pendingMcq = null;
    notifyListeners();
  }
}