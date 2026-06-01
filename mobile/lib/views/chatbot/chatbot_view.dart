import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../models/chat_session_summary.dart';
import '../../models/chat_response.dart';
import '../../models/create_hotel_booking_request.dart';
import '../../models/create_fake_payment_request.dart';
import '../../core/app_theme.dart';
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
        if (!chatProvider.hasSessionExpired && _handledSessionExpired) {
          _handledSessionExpired = false;
        }

        _handleSessionExpired(chatProvider);

        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              if (chatProvider.errorMessage != null &&
                  !chatProvider.hasSessionExpired)
                _ChatErrorBanner(
                  message: chatProvider.errorMessage!,
                  canRetry: chatProvider.canRetryLastPrompt,
                  onRetry: chatProvider.retryLastPrompt,
                ),
              ChatInput(
                canSubmit: chatProvider.canSendMessage,
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
            onPressed: chatProvider.isLoadingSessions || chatProvider.isTyping
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
    if (chatProvider.currentSessionId != null &&
        chatProvider.currentSessionId!.isNotEmpty) {
      return 'Dang xem doan chat da luu';
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
        return MessageBubble(
          message: chatProvider.messages[index],
          onBookRoom: _handleBookRoom,
        );
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

  // --- AI FUNCTION CALLING INLINE BOOKING ---
  Future<void> _handleBookRoom(HotelCard card) async {
    if (card.rooms == null || card.rooms!.isEmpty) {
      _showToastMessage('Khách sạn hiện không có phòng trống.');
      return;
    }

    final userId = await context.read<AuthProvider>().getUserId() ?? 1;
    final availableRooms = card.rooms!;

    final now = DateTime.now();
    var checkIn = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    var checkOut = checkIn.add(const Duration(days: 1));
    var selectedRoom = availableRooms.first;
    var roomQuantity = 1;
    var isSubmitting = false;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final nights = checkOut.difference(checkIn).inDays.clamp(1, 365);
            final totalPrice = selectedRoom.pricePerNight * nights * roomQuantity;

            Future<void> pickDate({required bool isCheckIn}) async {
              final today = DateTime(now.year, now.month, now.day);
              final picked = await showDatePicker(
                context: context,
                initialDate: isCheckIn ? checkIn : checkOut,
                firstDate: today,
                lastDate: today.add(const Duration(days: 365)),
              );

              if (picked == null) {
                return;
              }

              setSheetState(() {
                if (isCheckIn) {
                  checkIn = DateTime(picked.year, picked.month, picked.day);
                  if (!checkOut.isAfter(checkIn)) {
                    checkOut = checkIn.add(const Duration(days: 1));
                  }
                } else {
                  final normalized = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                  if (normalized.isAfter(checkIn)) {
                    checkOut = normalized;
                  }
                }
              });
            }

            Future<void> submitBooking() async {
              if (!checkOut.isAfter(checkIn)) {
                _showToastMessage('Ngày trả phòng phải sau ngày nhận phòng.');
                return;
              }

              if (roomQuantity > selectedRoom.availableQty) {
                _showToastMessage('Số phòng đặt vượt quá số phòng còn trống.');
                return;
              }

              setSheetState(() => isSubmitting = true);
              final tripProvider = context.read<TripProvider>();
              final createdTrip = await tripProvider.createHotelBooking(
                CreateHotelBookingRequest(
                  userId: userId,
                  hotelId: card.id ?? 0,
                  roomId: selectedRoom.id,
                  destinationId: card.destinationId,
                  destinationName: card.destinationName,
                  title: 'Đặt phòng - ${card.name}',
                  checkInDate: checkIn,
                  checkOutDate: checkOut,
                  quantity: roomQuantity,
                ),
              );

              if (createdTrip == null) {
                setSheetState(() => isSubmitting = false);
                _showToastMessage(
                  tripProvider.error ?? 'Không thể tạo đơn đặt phòng.',
                );
                return;
              }

              if (!mounted || !sheetContext.mounted) {
                return;
              }

              setSheetState(() => isSubmitting = false);
              Navigator.of(sheetContext).pop();
              await _openFakePaymentSheet(
                tripId: createdTrip.tripId,
                hotelName: card.name,
                roomType: selectedRoom.roomType,
                amount: totalPrice,
              );
            }

            final appSettings = context.read<AppSettingsProvider>();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      card.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BookingDateTile(
                            label: 'Nhận phòng',
                            value: _formatDate(checkIn),
                            onTap: () => pickDate(isCheckIn: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BookingDateTile(
                            label: 'Trả phòng',
                            value: _formatDate(checkOut),
                            onTap: () => pickDate(isCheckIn: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedRoom.id,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(18),
                          items: availableRooms.map((room) {
                            return DropdownMenuItem<int>(
                              value: room.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    room.roomType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                  Text(
                                    '${room.capacity} người • ${room.availableQty} phòng • ${appSettings.formatCurrency(room.pricePerNight)}/đêm',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isSubmitting
                              ? null
                              : (roomId) {
                                  if (roomId == null) {
                                    return;
                                  }

                                  final room = availableRooms.firstWhere(
                                    (item) => item.id == roomId,
                                  );
                                  setSheetState(() {
                                    selectedRoom = room;
                                    if (roomQuantity > selectedRoom.availableQty) {
                                      roomQuantity = selectedRoom.availableQty;
                                    }
                                  });
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDefault),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Số phòng',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: roomQuantity <= 1
                                ? null
                                : () => setSheetState(() => roomQuantity--),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Text(
                            '$roomQuantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: roomQuantity >= selectedRoom.availableQty
                                ? null
                                : () => setSheetState(() => roomQuantity++),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$nights đêm • ${selectedRoom.capacity} người/phòng • Còn ${selectedRoom.availableQty} phòng',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng tiền',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        Text(
                          appSettings.formatCurrency(totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submitBooking,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text(
                                'Xác nhận đặt phòng',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openFakePaymentSheet({
    required int tripId,
    required String hotelName,
    required String roomType,
    required double amount,
  }) async {
    var paymentMethod = 'Momo';
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitPayment() async {
              setSheetState(() => isSubmitting = true);

              final tripProvider = context.read<TripProvider>();
              final paidTrip = await tripProvider.completeFakePayment(
                tripId,
                CreateFakePaymentRequest(paymentMethod: paymentMethod),
              );

              if (!mounted || !sheetContext.mounted) {
                return;
              }

              setSheetState(() => isSubmitting = false);

              if (paidTrip == null) {
                _showToastMessage(
                  tripProvider.error ?? 'Thanh toán thử nghiệm thất bại.',
                );
                return;
              }

              Navigator.of(sheetContext).pop();
              _showToastMessage('Thanh toán thành công. Đơn đặt phòng đã được ghi nhận.');
            }

            final appSettings = context.read<AppSettingsProvider>();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Thanh toán thử nghiệm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$hotelName • $roomType',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Số tiền cần thanh toán',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          Text(
                            appSettings.formatCurrency(amount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PaymentMethodChip(
                          label: 'Momo',
                          selected: paymentMethod == 'Momo',
                          onTap: () => setSheetState(() => paymentMethod = 'Momo'),
                        ),
                        _PaymentMethodChip(
                          label: 'VNPay',
                          selected: paymentMethod == 'Vnpay',
                          onTap: () => setSheetState(() => paymentMethod = 'Vnpay'),
                        ),
                        _PaymentMethodChip(
                          label: 'Thẻ',
                          selected: paymentMethod == 'Card',
                          onTap: () => setSheetState(() => paymentMethod = 'Card'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submitPayment,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text(
                                'Thanh toán ngay',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showToastMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  final String message;
  final bool canRetry;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
              ),
            ),
          ),
          if (canRetry)
            TextButton(
              onPressed: onRetry,
              child: const Text('Thu lai'),
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

class _BookingDateTile extends StatelessWidget {
  const _BookingDateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9FFF0) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF166534) : AppColors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
