import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../models/chat_session_summary.dart';
import '../../widgets/chatbot/chat_input.dart';
import '../../widgets/chatbot/message_bubble.dart';
import '../../widgets/chatbot/quick_action_chips.dart';
import '../../widgets/chatbot/typing_indicator.dart';
import '../../widgets/chatbot/welcome_screen.dart';
import '../profile/profile_session_helper.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final ScrollController _scrollController = ScrollController();
  bool _handledSessionExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        _handleSessionExpired(chatProvider);

        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Column(
            children: [
              _buildHeader(chatProvider),
              Expanded(
                child: _buildBody(chatProvider),
              ),
              if (chatProvider.suggestions.isNotEmpty &&
                  !chatProvider.isTyping &&
                  !chatProvider.isLoadingHistory)
                QuickActionChips(
                  actions: chatProvider.suggestions,
                  onTap: (action) => chatProvider.onQuickActionTap(action),
                ),
              if (chatProvider.suggestions.isNotEmpty &&
                  !chatProvider.isTyping &&
                  !chatProvider.isLoadingHistory)
                const SizedBox(height: 6),
              ChatInput(
                onSend: (text) => chatProvider.sendMessage(text),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ChatProvider chatProvider) {
    if (chatProvider.isLoadingHistory && chatProvider.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.messages.isEmpty) {
      return WelcomeScreen(
        onQuickAction: (action) => chatProvider.onQuickActionTap(action),
      );
    }

    return _buildMessageList(chatProvider);
  }

  Widget _buildHeader(ChatProvider chatProvider) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF80ed99), Color(0xFF38ef7d)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF80ed99).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sky Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: chatProvider.isTyping
                            ? Colors.amber
                            : const Color(0xFF80ed99),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _buildStatusText(chatProvider),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: chatProvider.isLoadingSessions
                ? null
                : () => _showSessionHistory(chatProvider),
            icon: Icon(
              Icons.history_rounded,
              color: Colors.white.withValues(alpha: 0.78),
            ),
            tooltip: 'Lich su doan chat',
          ),
          IconButton(
            onPressed: chatProvider.isTyping ? null : chatProvider.startNewChat,
            icon: Icon(
              Icons.add_comment_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            tooltip: 'Tao doan chat moi',
          ),
        ],
      ),
    );
  }

  String _buildStatusText(ChatProvider chatProvider) {
    if (chatProvider.isLoadingHistory) {
      return 'Dang tai lich su...';
    }
    if (chatProvider.isTyping) {
      return 'Dang tra loi...';
    }
    return 'Truc tuyen';
  }

  Widget _buildMessageList(ChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatProvider.messages.length && chatProvider.isTyping) {
          return const TypingIndicator();
        }
        return MessageBubble(message: chatProvider.messages[index]);
      },
    );
  }

  Future<void> _showSessionHistory(ChatProvider chatProvider) async {
    await chatProvider.loadSessions();
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lich su doan chat',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            provider.startNewChat();
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text('Chat moi'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: provider.isLoadingSessions
                          ? const Center(child: CircularProgressIndicator())
                          : provider.sessions.isEmpty
                              ? _EmptySessionState(
                                  onCreateNew: () {
                                    provider.startNewChat();
                                    Navigator.of(sheetContext).pop();
                                  },
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: provider.sessions.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final session = provider.sessions[index];
                                    return _SessionTile(
                                      session: session,
                                      isActive:
                                          session.sessionId == provider.currentSessionId,
                                      onOpen: () async {
                                        Navigator.of(sheetContext).pop();
                                        await provider.openSession(session.sessionId);
                                      },
                                      onDelete: () async {
                                        await provider.deleteSession(session.sessionId);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSessionExpired(ChatProvider chatProvider) async {
    if (!chatProvider.hasSessionExpired || _handledSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(
      context,
      message: chatProvider.errorMessage,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _EmptySessionState extends StatelessWidget {
  const _EmptySessionState({required this.onCreateNew});

  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 44, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Chua co doan chat nao duoc luu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreateNew,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Bat dau chat moi'),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onOpen,
    required this.onDelete,
  });

  final ChatSessionSummary session;
  final bool isActive;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onOpen,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isActive
            ? const Color(0xFF80ed99).withValues(alpha: 0.22)
            : colorScheme.surfaceContainerHighest,
        child: Icon(
          isActive ? Icons.chat_rounded : Icons.history_rounded,
          color: isActive ? const Color(0xFF2D6A4F) : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        _buildTitle(session),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _buildSubtitle(session),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
        tooltip: 'Xoa doan chat',
      ),
    );
  }

  String _buildTitle(ChatSessionSummary session) {
    final preview = session.previewText.trim();
    if (preview.isEmpty) {
      return 'Doan chat';
    }

    if (preview.length <= 28) {
      return preview;
    }

    return '${preview.substring(0, 28)}...';
  }

  String _buildSubtitle(ChatSessionSummary session) {
    final day = session.lastUpdatedAt.day.toString().padLeft(2, '0');
    final month = session.lastUpdatedAt.month.toString().padLeft(2, '0');
    final hour = session.lastUpdatedAt.hour.toString().padLeft(2, '0');
    final minute = session.lastUpdatedAt.minute.toString().padLeft(2, '0');
    final preview = session.previewText.trim().isEmpty
        ? 'Khong co noi dung xem truoc'
        : session.previewText.trim();

    return '$day/$month $hour:$minute - $preview';
  }
}
