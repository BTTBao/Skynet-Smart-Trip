import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/app_currency_formatter.dart';

class VehicleRentalDetailScreen extends StatefulWidget {
  const VehicleRentalDetailScreen({super.key, required this.shopId});

  final int shopId;

  @override
  State<VehicleRentalDetailScreen> createState() =>
      _VehicleRentalDetailScreenState();
}

class _VehicleRentalDetailScreenState extends State<VehicleRentalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadVehicleRentalShopDetail(widget.shopId);
    });
  }

  Future<void> _callShop(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'ManualMotorbike':
      case 'Scooter':
        return Icons.two_wheeler_rounded;
      case 'Car':
        return Icons.directions_car_rounded;
      case 'MultiSeatCar':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.directions_car_filled_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Consumer<CatalogProvider>(
        builder: (context, provider, _) {
          final detail = provider.selectedVehicleRentalShop;

          if (provider.isLoadingVehicleRentalDetail && detail == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.error ?? 'Không tải được thông tin cửa hàng.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        detail.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFDDEEE0),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeading,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${detail.address} • ${detail.destinationName}',
                                    style: const TextStyle(
                                      color: AppColors.textBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (detail.description != null &&
                                detail.description!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                detail.description!,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bảng giá thuê xe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...detail.vehicleOptions.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VehicleOptionCard(
                            option: option,
                            icon: _vehicleIcon(option.vehicleType),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CatalogProvider>(
        builder: (context, provider, _) {
          final detail = provider.selectedVehicleRentalShop;
          if (detail == null) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton.icon(
                onPressed: () => _callShop(detail.phoneNumber),
                icon: const Icon(Icons.phone_rounded, color: Colors.white),
                label: Text(
                  'Liên hệ ${detail.phoneNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  const _VehicleOptionCard({
    required this.option,
    required this.icon,
  });

  final CatalogVehicleRentalOption option;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.vehicleTypeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                    fontSize: 16,
                  ),
                ),
                if (option.maxSeats != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tối đa ${option.maxSeats} chỗ',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  option.isAvailable ? 'Còn xe' : 'Hết xe',
                  style: TextStyle(
                    color: option.isAvailable
                        ? AppColors.primary
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppCurrencyFormatter.format(option.pricePerDay)}/ngày',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
