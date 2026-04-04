import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chatbot/message_bubble.dart';
import '../../widgets/chatbot/chat_input.dart';
import '../../widgets/chatbot/typing_indicator.dart';
import '../../widgets/chatbot/quick_action_chips.dart';
import '../../widgets/chatbot/welcome_screen.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).initialize();
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
      builder: (context, chatProvider, child) {
        // Auto-scroll when messages change
        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Column(
            children: [
              // Custom header
              _buildHeader(chatProvider),
              // Chat content
              Expanded(
                child: chatProvider.messages.length <= 1
                    ? WelcomeScreen(
                        onQuickAction: (action) => chatProvider.onQuickActionTap(action),
                      )
                    : _buildMessageList(chatProvider),
              ),
              // Quick actions
              if (chatProvider.suggestions.isNotEmpty && !chatProvider.isTyping)
                QuickActionChips(
                  actions: chatProvider.suggestions,
                  onTap: (action) => chatProvider.onQuickActionTap(action),
                ),
              if (chatProvider.suggestions.isNotEmpty && !chatProvider.isTyping)
                const SizedBox(height: 6),
              // Input
              ChatInput(
                onSend: (text) => chatProvider.sendMessage(text),
              ),
            ],
          ),
        );
      },
    );
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
          // Sky avatar
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
          // Name & status
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
                      chatProvider.isTyping ? 'Đang trả lời...' : 'Trực tuyến',
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
          // Refresh button
          IconButton(
            onPressed: () => chatProvider.clearChat(),
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            tooltip: 'Cuộc trò chuyện mới',
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
