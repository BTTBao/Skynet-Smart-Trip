import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/create_trip_itinerary_request.dart';
import '../../models/create_trip_request.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session_summary.dart';
import '../../models/chat_response.dart';
import '../../core/app_theme.dart';
import '../../widgets/chatbot/chat_input.dart';
import '../../widgets/chatbot/message_bubble.dart';
import '../../widgets/chatbot/quick_action_chips.dart';
import '../../widgets/chatbot/typing_indicator.dart';
import '../../widgets/chatbot/welcome_screen.dart';
import '../catalog/hotel_detail_view.dart';
import '../profile/profile_session_helper.dart';
import '../transport/transport_search_screen.dart';
import '../trip/trip_itinerary_detail_view.dart';

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _handleSessionExpired(chatProvider);
        });

        if (chatProvider.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _scrollToBottom();
          });
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildHeader(chatProvider),
              Expanded(child: _buildBody(chatProvider)),
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
            tooltip: 'Lịch sử đoạn chat',
          ),
          IconButton(
            onPressed: chatProvider.isTyping ? null : chatProvider.startNewChat,
            icon: Icon(
              Icons.add_comment_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            tooltip: 'Tạo đoạn chat mới',
          ),
        ],
      ),
    );
  }

  String _buildStatusText(ChatProvider chatProvider) {
    if (chatProvider.isLoadingHistory) {
      return 'Đang tải lịch sử...';
    }
    if (chatProvider.currentSessionId != null &&
        chatProvider.currentSessionId!.isNotEmpty) {
      return 'Đang xem đoạn chat đã lưu';
    }
    if (chatProvider.isTyping) {
      return 'Đang trả lời...';
    }
    return 'Trực tuyến';
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
          onBookTransport: _handleBookTransport,
          onBookPlannedHotel: _handleBookPlannedHotel,
          onBookPlannedTransport: _handleBookPlannedTransport,
          onSaveItinerary: _saveSuggestedItinerary,
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
                            'Lịch sử đoạn chat',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            provider.startNewChat();
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text('Chat mới'),
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
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final session = provider.sessions[index];
                                return _SessionTile(
                                  session: session,
                                  isActive:
                                      session.sessionId ==
                                      provider.currentSessionId,
                                  onOpen: () async {
                                    Navigator.of(sheetContext).pop();
                                    await provider.openSession(
                                      session.sessionId,
                                    );
                                  },
                                  onDelete: () async {
                                    await provider.deleteSession(
                                      session.sessionId,
                                    );
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
    await showSessionExpiredDialog(context, message: chatProvider.errorMessage);
  }

  // --- AI FUNCTION CALLING INLINE BOOKING ---
  Future<void> _handleBookRoom(HotelCard card) async {
    final hotelId = card.id;
    if (hotelId == null || hotelId <= 0) {
      _showToastMessage('Không tìm thấy thông tin khách sạn để mở màn đặt.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelDetailView(hotelId: hotelId, autoOpenBookingSheet: true)),
    );
  }

  Future<void> _handleBookTransport(TransportCard card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransportSearchScreen(
          toDestId: card.toDestinationId,
          toDestName: card.toDestinationName,
          initialDate:
              card.departureTime ?? _resolveLatestChatBookingDates().checkIn,
        ),
      ),
    );
  }

  Future<void> _handleBookPlannedHotel(HotelPlanSuggestion hotel) async {
    final hotelId = hotel.hotelId;
    if (hotelId == null || hotelId <= 0) {
      _showToastMessage('Không tìm thấy thông tin khách sạn để mở màn đặt.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelDetailView(hotelId: hotelId, autoOpenBookingSheet: true)),
    );
  }

  Future<void> _handleBookPlannedTransport(
    TransportPlanSuggestion transport,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransportSearchScreen(
          toDestId: transport.toDestinationId,
          toDestName: transport.toDestinationName ?? '',
          initialDate:
              transport.departureTime ??
              _resolveLatestChatBookingDates().checkIn,
          initialScheduleId: transport.scheduleId,
        ),
      ),
    );
  }

  Future<void> _saveSuggestedItinerary(SuggestedItinerary itinerary) async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (userId == null) {
      _showToastMessage('Bạn cần đăng nhập để lưu chuyến đi.');
      return;
    }

    final tripProvider = context.read<TripProvider>();
    final prefill = _resolveLatestChatBookingDates();
    final today = _dateOnly(DateTime.now());
    final startDate = prefill.checkIn ?? today.add(const Duration(days: 1));
    final totalDays = itinerary.totalDays.clamp(1, 30).toInt();
    final endDate =
        prefill.checkOut ?? startDate.add(Duration(days: totalDays - 1));
    final tripTitle = _buildTripTitle(itinerary, startDate, endDate);

    final createdTrip = await tripProvider.createTrip(
      CreateTripRequest(
        userId: userId,
        title: tripTitle,
        startDate: startDate,
        endDate: endDate,
        destinationId: itinerary.destinationId,
        destinationName: itinerary.destination,
        status: 'DRAFT',
      ),
    );

    if (createdTrip == null) {
      _showToastMessage(tripProvider.error ?? 'Không thể lưu chuyến đi.');
      return;
    }

    var saveOk = true;

    final transport = itinerary.transportSuggestion;
    if (transport?.scheduleId != null) {
      final itineraryId = await tripProvider.addItinerary(
        createdTrip.tripId,
        CreateTripItineraryRequest(
          dayNumber: 1,
          serviceType: 'BUS',
          serviceId: transport!.scheduleId!,
          quantity: 1,
          bookedPrice: transport.price,
          serviceDate: startDate,
        ),
      );
      saveOk = itineraryId != null;
    }

    if (saveOk) {
      final hotel = itinerary.hotelSuggestion;
      if (hotel?.roomId != null) {
        final nights = endDate
            .difference(startDate)
            .inDays
            .clamp(1, 30)
            .toInt();
        final itineraryId = await tripProvider.addItinerary(
          createdTrip.tripId,
          CreateTripItineraryRequest(
            dayNumber: 1,
            serviceType: 'HOTEL',
            serviceId: hotel!.roomId!,
            quantity: 1,
            bookedPrice: (hotel.pricePerNight ?? 0) * nights,
            serviceDate: startDate,
          ),
        );
        saveOk = itineraryId != null;
      }
    }

    if (!saveOk) {
      _showToastMessage(
        tripProvider.error ?? 'Đã tạo chuyến đi nhưng chưa lưu được plan.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    _showToastMessage('Đã lưu plan vào chuyến đi.');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: createdTrip.tripId,
          tripTitle: createdTrip.title,
          startDate: createdTrip.startDate,
          endDate: createdTrip.endDate,
        ),
      ),
    );
  }

  _ChatBookingPrefill _resolveLatestChatBookingDates() {
    final messages = context.read<ChatProvider>().messages.reversed;

    for (final message in messages) {
      if (message.sender != MessageSender.user) {
        continue;
      }

      final dates = _extractDatesFromText(message.text);
      if (dates.isEmpty) {
        continue;
      }

      final checkIn = dates.first;
      final checkOut = dates.length > 1
          ? _resolveCheckOutDate(checkIn, dates[1])
          : checkIn.add(const Duration(days: 1));
      return _ChatBookingPrefill(checkIn: checkIn, checkOut: checkOut);
    }

    return const _ChatBookingPrefill();
  }

  List<DateTime> _extractDatesFromText(String text) {
    final normalizedText = text.toLowerCase();
    final today = _dateOnly(DateTime.now());
    final matches = <_DateMatch>[];

    void addMatch(DateTime date, int start) {
      final normalizedDate = _dateOnly(date);
      final exists = matches.any(
        (item) => item.start == start && item.date == normalizedDate,
      );
      if (!exists) {
        matches.add(_DateMatch(start: start, date: normalizedDate));
      }
    }

    for (final match in RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{4}))?\b',
    ).allMatches(normalizedText)) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3) ?? '') ?? today.year;
      final parsed = _tryBuildDate(day, month, year);
      if (parsed != null) {
        addMatch(_rollForwardIfPast(parsed), match.start);
      }
    }

    for (final match in RegExp(
      r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b',
    ).allMatches(normalizedText)) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      final parsed = _tryBuildDate(day, month, year);
      if (parsed != null) {
        addMatch(parsed, match.start);
      }
    }

    if (normalizedText.contains('ngay kia')) {
      addMatch(
        today.add(const Duration(days: 2)),
        normalizedText.indexOf('ngay kia'),
      );
    }
    if (normalizedText.contains('ngay mai')) {
      addMatch(
        today.add(const Duration(days: 1)),
        normalizedText.indexOf('ngay mai'),
      );
    }
    if (normalizedText.contains('hom nay')) {
      addMatch(today, normalizedText.indexOf('hom nay'));
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches.map((item) => item.date).toList(growable: false);
  }

  DateTime? _tryBuildDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) {
      return null;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }

    return candidate;
  }

  DateTime _rollForwardIfPast(DateTime date) {
    final today = _dateOnly(DateTime.now());
    if (!date.isBefore(today)) {
      return date;
    }

    return DateTime(today.year + 1, date.month, date.day);
  }

  DateTime _resolveCheckOutDate(DateTime checkIn, DateTime rawCheckOut) {
    final normalizedCheckIn = _dateOnly(checkIn);
    final normalizedCheckOut = _dateOnly(rawCheckOut);
    if (normalizedCheckOut.isAfter(normalizedCheckIn)) {
      return normalizedCheckOut;
    }
    return normalizedCheckIn.add(const Duration(days: 1));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _buildTripTitle(
    SuggestedItinerary itinerary,
    DateTime startDate,
    DateTime endDate,
  ) {
    final startLabel =
        '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}';
    final endLabel =
        '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}';
    return '${itinerary.destination} $startLabel - $endLabel';
  }

  void _showToastMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
            'Chưa có đoạn chat nào được lưu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreateNew,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Bắt đầu chat mới'),
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
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9A3412), fontSize: 13),
            ),
          ),
          if (canRetry)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
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
          color: isActive
              ? const Color(0xFF2D6A4F)
              : colorScheme.onSurfaceVariant,
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
        tooltip: 'Lịch sử đoạn chat',
      ),
    );
  }

  String _buildTitle(ChatSessionSummary session) {
    final preview = session.previewText.trim();
    if (preview.isEmpty) {
      return 'Đoạn chat';
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
        ? 'Không có nội dung xem trước'
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
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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

class _ChatBookingPrefill {
  const _ChatBookingPrefill({this.checkIn, this.checkOut});

  final DateTime? checkIn;
  final DateTime? checkOut;
}

class _DateMatch {
  const _DateMatch({required this.start, required this.date});

  final int start;
  final DateTime date;
}

