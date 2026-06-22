import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/app_currency_formatter.dart';
import 'vehicle_rental_detail_screen.dart';

class VehicleRentalListScreen extends StatefulWidget {
  const VehicleRentalListScreen({
    super.key,
    this.destinationId,
    this.destinationName,
  });

  final int? destinationId;
  final String? destinationName;

  @override
  State<VehicleRentalListScreen> createState() =>
      _VehicleRentalListScreenState();
}

class _VehicleRentalListScreenState extends State<VehicleRentalListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().searchVehicleRentalShops(
            destinationId: widget.destinationId,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<CatalogProvider>().searchVehicleRentalShops(
          query: _searchController.text,
          destinationId: widget.destinationId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.destinationName != null
        ? 'Thuê xe tại ${widget.destinationName}'
        : 'Dịch vụ thuê xe tự lái';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.bgPage,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Tìm cửa hàng, địa chỉ...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<CatalogProvider>(
              builder: (context, provider, _) {
                if (provider.isSearchingVehicleRentals &&
                    provider.vehicleRentalSearchResult.items.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final items = provider.vehicleRentalSearchResult.items;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      provider.error ?? 'Chưa có cửa hàng cho thuê xe.',
                      style: const TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.searchVehicleRentalShops(
                    query: _searchController.text,
                    destinationId: widget.destinationId,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _VehicleRentalShopCard(
                      shop: items[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VehicleRentalDetailScreen(
                            shopId: items[index].id,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleRentalShopCard extends StatelessWidget {
  const _VehicleRentalShopCard({
    required this.shop,
    required this.onTap,
  });

  final CatalogVehicleRentalShopCard shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(22),
              ),
              child: Image.network(
                shop.imageUrl,
                width: 110,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 110,
                  height: 120,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.destinationName,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (shop.vehicleTypeLabels.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: shop.vehicleTypeLabels
                            .take(3)
                            .map(
                              (label) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Từ ${AppCurrencyFormatter.format(shop.minPricePerDay)}/ngày',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
