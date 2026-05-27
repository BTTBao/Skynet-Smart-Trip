import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/app_currency_formatter.dart';

class BusDetailView extends StatefulWidget {
  const BusDetailView({super.key, required this.scheduleId});

  final int scheduleId;

  @override
  State<BusDetailView> createState() => _BusDetailViewState();
}

class _BusDetailViewState extends State<BusDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadBusDetail(widget.scheduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: const Text('Chi tiết chuyến xe')),
      body: Consumer<CatalogProvider>(
        builder: (context, provider, _) {
          final detail = provider.selectedBus;

          if (provider.isLoadingBusDetail && detail == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (detail == null) {
            return Center(
              child: Text(
                provider.error ?? 'Không tải được thông tin chuyến xe.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.companyName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${detail.fromDestination} → ${detail.toDestination}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      label: 'Khởi hành',
                      value:
                          detail.departureTime?.toString() ?? 'Chưa cập nhật',
                    ),
                    _InfoRow(
                      label: 'Đến nơi',
                      value: detail.arrivalTime?.toString() ?? 'Chưa cập nhật',
                    ),
                    _InfoRow(label: 'Số ghế', value: '${detail.totalSeats}'),
                    _InfoRow(
                      label: 'Hotline',
                      value: detail.hotline.isEmpty
                          ? 'Đang cập nhật'
                          : detail.hotline,
                    ),
                    _InfoRow(
                      label: 'Đánh giá',
                      value: '${detail.rating} ★ (${detail.reviewCount})',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppCurrencyFormatter.format(detail.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đánh giá gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 12),
              ...detail.reviews.map(
                (review) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(review.comment),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
