import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_response.dart';
import '../../providers/app_settings_provider.dart';

class TransportCardBubble extends StatelessWidget {
  const TransportCardBubble({
    super.key,
    required this.cards,
    this.onBookTransport,
  });

  final List<TransportCard> cards;
  final void Function(TransportCard card)? onBookTransport;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .map((card) => _buildCard(context, settings, card))
              .toList(),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppSettingsProvider settings,
    TransportCard card,
  ) {
    final routeLabel =
        '${card.fromDestinationName ?? 'Điểm đi'} -> ${card.toDestinationName ?? 'Điểm đến'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FFF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Color(0xFF0D6B42),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.companyName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (card.departureTime != null)
                  _InfoChip(label: 'Đi: ${_formatDateTime(card.departureTime!)}'),
                if (card.arrivalTime != null)
                  _InfoChip(label: 'Đến: ${_formatDateTime(card.arrivalTime!)}'),
                if (card.totalSeats != null)
                  _InfoChip(label: '${card.totalSeats} ghế'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.price == null
                        ? 'Liên hệ giá'
                        : settings.formatCurrency(card.price!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D6B42),
                    ),
                  ),
                ),
                if (onBookTransport != null)
                  ElevatedButton(
                    onPressed: () => onBookTransport!(card),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6B42),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Đặt xe'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
