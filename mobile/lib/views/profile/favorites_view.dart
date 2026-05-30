import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_favorite.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import 'profile_session_helper.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  bool _handledSessionExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadFavorites(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        _handleSessionExpired(provider);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              context.tr(vi: 'Dich vu yeu thich', en: 'Favorites'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(ProfileProvider provider) {
    if (provider.isLoadingFavorites && provider.favorites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null &&
        provider.favorites.isEmpty &&
        !provider.hasSessionExpired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => provider.loadFavorites(forceRefresh: true),
                child: Text(context.tr(vi: 'Thu lai', en: 'Retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadFavorites(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            EmptyStatePlaceholder(
              icon: Icons.favorite_outline,
              title: context.tr(
                vi: 'Chua co muc yeu thich',
                en: 'No favorites yet',
              ),
              subtitle: context.tr(
                vi: 'Khach san va chuyen xe ban danh dau se hien thi tai day.',
                en: 'Saved hotels and bus routes will appear here.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavorites(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final favorite = provider.favorites[index];
          return _FavoriteCard(
            favorite: favorite,
            onRemove: () => _removeFavorite(provider, favorite),
          );
        },
      ),
    );
  }

  Future<void> _removeFavorite(
    ProfileProvider provider,
    UserFavorite favorite,
  ) async {
    final success = await provider.removeFavorite(favorite.wishId);
    if (!mounted) {
      return;
    }

    if (provider.hasSessionExpired) {
      await _handleSessionExpired(provider);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.trRead(
                  vi: 'Da xoa khoi yeu thich.',
                  en: 'Removed from favorites.',
                )
              : (provider.error ??
                  context.trRead(
                    vi: 'Khong the xoa muc yeu thich.',
                    en: 'Unable to remove favorite.',
                  )),
        ),
      ),
    );
  }

  Future<void> _handleSessionExpired(ProfileProvider provider) async {
    if (_handledSessionExpired || !provider.hasSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(context, message: provider.error);
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.onRemove,
  });

  final UserFavorite favorite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isHotel = favorite.itemType.toLowerCase() == 'hotel';
    final accentColor =
        isHotel ? const Color(0xFF1A759F) : const Color(0xFFEF476F);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isHotel ? Icons.hotel_outlined : Icons.directions_bus_outlined,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  favorite.subtitle,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (favorite.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    favorite.description!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (favorite.priceLabel?.isNotEmpty == true)
                      _InfoChip(label: favorite.priceLabel!),
                    if (favorite.statusLabel?.isNotEmpty == true)
                      _InfoChip(label: favorite.statusLabel!),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoa khoi yeu thich',
          ),
        ],
      ),
    );
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
