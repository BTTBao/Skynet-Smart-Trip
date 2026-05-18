import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/chat_history_result.dart';
import '../models/chat_message.dart';
import '../models/chat_response.dart';
import '../models/chat_session_summary.dart';
import '../services/api_service_base.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final List<ChatMessage> _messages = [];
  final List<ChatSessionSummary> _sessions = [];
  List<QuickAction> _suggestions = const [];

  bool _isTyping = false;
  bool _isInitialized = false;
  bool _isLoadingHistory = false;
  bool _isLoadingSessions = false;
  String? _errorMessage;
  int? _lastStatusCode;
  String? _currentSessionId;
  String? _activeUserKey;
  String? _lastFailedPrompt;
  bool _isViewingHistorySession = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSessionSummary> get sessions => List.unmodifiable(_sessions);
  List<QuickAction> get suggestions => _suggestions;
  bool get isTyping => _isTyping;
  bool get isInitialized => _isInitialized;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get hasMessages => _messages.isNotEmpty;
  bool get hasSessions => _sessions.isNotEmpty;
  String? get errorMessage => _errorMessage;
  bool get hasSessionExpired => _lastStatusCode == 401;
  String? get currentSessionId => _currentSessionId;
  String? get lastFailedPrompt => _lastFailedPrompt;
  bool get isViewingHistorySession => _isViewingHistorySession;
  bool get canRetryLastPrompt =>
      _lastFailedPrompt != null &&
      _lastFailedPrompt!.trim().isNotEmpty &&
      !isTyping;
  bool get canSendMessage => !isLoadingHistory;

  Future<void> initialize({bool forceRefresh = false}) async {
    final userChanged = await _syncActiveUser();

    if (_isInitialized && !forceRefresh && !userChanged) {
      return;
    }

    _isInitialized = true;
    _suggestions = _defaultSuggestions;
    notifyListeners();

    if (_activeUserKey == null) {
      return;
    }

    await _loadSuggestions();
    await Future.wait([
      loadSessions(notify: false),
      loadHistory(notify: false),
    ]);
    notifyListeners();
  }

  Future<void> loadHistory({
    String? sessionId,
    bool notify = true,
  }) async {
    await _syncActiveUser();
    if (_activeUserKey == null) {
      _messages.clear();
      _currentSessionId = null;
      _isLoadingHistory = false;
      if (notify) {
        notifyListeners();
      }
      return;
    }

    _isLoadingHistory = true;
    _clearError();
    if (notify) {
      notifyListeners();
    }

    try {
      final result = await _chatService.getHistory(
        sessionId: sessionId,
        limit: 50,
      );
      _applyHistoryResult(
        result,
        openedFromHistory: sessionId != null && sessionId.trim().isNotEmpty,
      );
    } catch (error) {
      _setError(error);
      _messages.clear();
    } finally {
      _isLoadingHistory = false;
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(String text) async {
    await _syncActiveUser();
    if (_activeUserKey == null) {
      _setError(ApiException(401, 'Unauthorized'));
      notifyListeners();
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) {
      return;
    }

    _clearError();
    _isViewingHistorySession = false;
    _messages.add(
      ChatMessage(
        text: trimmed,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isTyping = true;
    _lastFailedPrompt = null;
    notifyListeners();

    try {
      final botResponse = await _chatService.sendMessage(
        trimmed,
        sessionId: _currentSessionId,
      );

      _currentSessionId = botResponse.sessionId ?? _currentSessionId;
      _messages.add(ChatMessage.fromResponse(botResponse));

      if (botResponse.quickActions != null &&
          botResponse.quickActions!.isNotEmpty) {
        _suggestions = botResponse.quickActions!;
      }

      await loadSessions(notify: false);
    } catch (error) {
      _setError(error);
      _lastFailedPrompt = trimmed;
      _messages.add(
        ChatMessage(
          text: _buildFriendlyErrorMessage(error),
          sender: MessageSender.bot,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> loadSessions({bool notify = true}) async {
    await _syncActiveUser();
    if (_activeUserKey == null) {
      _sessions.clear();
      _isLoadingSessions = false;
      if (notify) {
        notifyListeners();
      }
      return;
    }

    _isLoadingSessions = true;
    if (notify) {
      notifyListeners();
    }

    try {
      final sessionItems = await _chatService.getSessions(limit: 20);
      _sessions
        ..clear()
        ..addAll(sessionItems);
    } catch (error) {
      _setError(error);
      _sessions.clear();
    } finally {
      _isLoadingSessions = false;
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> openSession(String sessionId) async {
    final normalized = sessionId.trim();
    if (normalized.isEmpty) {
      return;
    }

    _currentSessionId = normalized;
    _isViewingHistorySession = true;
    notifyListeners();
    await loadHistory(sessionId: normalized);
  }

  void startNewChat() {
    _messages.clear();
    _currentSessionId = null;
    _isViewingHistorySession = false;
    _lastFailedPrompt = null;
    _clearError();
    notifyListeners();
  }

  void resetForSignedOutUser() {
    _activeUserKey = null;
    _messages.clear();
    _sessions.clear();
    _currentSessionId = null;
    _isTyping = false;
    _isLoadingHistory = false;
    _isLoadingSessions = false;
    _isViewingHistorySession = false;
    _lastFailedPrompt = null;
    _clearError();
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    final normalized = sessionId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final previousMessages = List<ChatMessage>.from(_messages);
    final previousSessionId = _currentSessionId;

    _sessions.removeWhere((item) => item.sessionId == normalized);
    if (_currentSessionId == normalized) {
      _currentSessionId = null;
      _messages.clear();
    }
    notifyListeners();

    try {
      await _chatService.clearHistory(sessionId: normalized);
    } catch (error) {
      _setError(error);
      if (previousSessionId == normalized) {
        _messages
          ..clear()
          ..addAll(previousMessages);
        _currentSessionId = previousSessionId;
      }
      await loadSessions(notify: false);
      notifyListeners();
    }
  }

  void onQuickActionTap(QuickAction action) {
    sendMessage(_resolveActionMessage(action));
  }

  Future<void> _loadSuggestions() async {
    try {
      final serverSuggestions = await _chatService.getSuggestions();
      if (serverSuggestions.isNotEmpty) {
        _suggestions = serverSuggestions;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _applyHistoryResult(
    ChatHistoryResult result, {
    required bool openedFromHistory,
  }) {
    _currentSessionId = result.sessionId;
    _isViewingHistorySession = openedFromHistory;
    _messages
      ..clear()
      ..addAll(result.messages.map(ChatMessage.fromHistoryItem));
  }

  Future<bool> _syncActiveUser() async {
    final nextUserKey = await _readCurrentUserKey();
    if (_activeUserKey == nextUserKey) {
      return false;
    }

    _activeUserKey = nextUserKey;
    _messages.clear();
    _sessions.clear();
    _currentSessionId = null;
    _isTyping = false;
    _isLoadingHistory = false;
    _isLoadingSessions = false;
    _isViewingHistorySession = false;
    _lastFailedPrompt = null;
    _clearError();
    _isInitialized = false;
    notifyListeners();
    return true;
  }

  Future<String?> _readCurrentUserKey() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final subject =
          claims['nameid'] ??
          claims[
              'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          claims['sub'] ??
          claims['sid'] ??
          claims['name'];
      final userKey = subject?.toString().trim();
      if (userKey == null || userKey.isEmpty) {
        return null;
      }
      return userKey;
    } catch (_) {
      return null;
    }
  }

  void _clearError() {
    _errorMessage = null;
    _lastStatusCode = null;
  }

  Future<void> retryLastPrompt() async {
    final failedPrompt = _lastFailedPrompt;
    if (failedPrompt == null || failedPrompt.trim().isEmpty) {
      return;
    }

    await sendMessage(failedPrompt);
  }

  void _setError(Object error) {
    if (error is ApiException) {
      _lastStatusCode = error.statusCode;
      _errorMessage = _mapErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
      return;
    }

    _lastStatusCode = null;
    _errorMessage = _mapErrorMessage(
      error.toString().replaceFirst('Exception: ', ''),
    );
  }

  String _buildFriendlyErrorMessage(Object error) {
    if (error is ApiException && error.isUnauthorized) {
      return 'Phien dang nhap da het han. Vui long dang nhap lai de tiep tuc chat.';
    }

    return 'Sky dang gap su co ket noi. Ban thu lai trong it phut nua nhe.';
  }

  String _mapErrorMessage(String message, {int? statusCode}) {
    if (statusCode == 401) {
      return 'Phien dang nhap da het han. Vui long dang nhap lai.';
    }

    final lower = message.toLowerCase();
    final looksLikeConnectionIssue =
        lower.contains('timeout') ||
        lower.contains('backend') ||
        lower.contains('10.0.2.2') ||
        lower.contains('localhost') ||
        lower.contains('ket noi') ||
        lower.contains('socket') ||
        lower.contains('clientexception') ||
        lower.contains('handshake');

    if (looksLikeConnectionIssue || (statusCode != null && statusCode >= 500)) {
      return 'Khong the ket noi toi tro ly luc nay. Ban thu lai sau it phut nhe.';
    }

    return message;
  }

  String _resolveActionMessage(QuickAction action) {
    final payload = action.actionPayload.trim();
    final label = action.label.trim();

    if (payload.isEmpty) {
      return label;
    }

    final looksLikeInternalCommand =
        RegExp(r'^[A-Z0-9_]+$').hasMatch(payload) ||
        payload.startsWith('SHOW_') ||
        payload.startsWith('OPEN_') ||
        payload.startsWith('DETAIL_');

    if (looksLikeInternalCommand) {
      return label;
    }

    return payload;
  }

  static const List<QuickAction> _defaultSuggestions = [
    QuickAction(
      label: 'Goi y diem den',
      icon: 'explore',
      actionPayload: 'Goi y cho toi 3 diem den dep o Viet Nam',
    ),
    QuickAction(
      label: 'Lap lich trinh',
      icon: 'calendar',
      actionPayload: 'Lap lich trinh du lich Da Lat 3 ngay 2 dem',
    ),
    QuickAction(
      label: 'Tim khach san',
      icon: 'hotel',
      actionPayload: 'Tim khach san tot o Phu Quoc',
    ),
    QuickAction(
      label: 'Xem thoi tiet',
      icon: 'weather',
      actionPayload: 'Thoi tiet Da Nang hom nay the nao?',
    ),
  ];
}
