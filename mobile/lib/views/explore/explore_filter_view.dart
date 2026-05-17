import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/explore_provider.dart';
import 'explore_ui_constants.dart';

class ExploreFilterView extends StatefulWidget {
  const ExploreFilterView({super.key});

  @override
  State<ExploreFilterView> createState() => _ExploreFilterViewState();
}

class _ExploreFilterViewState extends State<ExploreFilterView> {
  late ExploreFilterState _temp;

  @override
  void initState() {
    super.initState();
    _temp = context.read<ExploreProvider>().filterState;
  }

  void _apply() {
    context.read<ExploreProvider>().applyFilterState(_temp);
    Navigator.of(context).maybePop();
  }

  void _reset() => setState(() => _temp = const ExploreFilterState());

  void _setSort(ExploreFilter sort) =>
      setState(() => _temp = _temp.copyWith(sortBy: sort));

  void _toggleCity(String slug) {
    final updated = Set<String>.from(_temp.selectedCities);
    if (updated.contains(slug)) {
      updated.remove(slug);
    } else {
      updated.add(slug);
    }
    setState(() => _temp = _temp.copyWith(selectedCities: updated));
  }

  void _setMinRating(double? r) =>
      setState(() => _temp = _temp.copyWith(minRating: r));

  void _togglePrice(ExplorePriceFilter pf) {
    final updated = Set<ExplorePriceFilter>.from(_temp.prices);
    if (updated.contains(pf)) {
      updated.remove(pf);
    } else {
      updated.add(pf);
    }
    setState(() => _temp = _temp.copyWith(prices: updated));
  }

  @override
  Widget build(BuildContext context) {
    final count = _temp.activeFilterCount;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(count),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          _SortSection(current: _temp.sortBy, onSelect: _setSort),
          const _Gap(),
          _RatingSection(current: _temp.minRating, onSelect: _setMinRating),
          const _Gap(),
          _CitySection(
            selectedCities: _temp.selectedCities,
            onToggleCity: _toggleCity,
          ),
          const _Gap(),
          _PriceSection(selected: _temp.prices, onToggle: _togglePrice),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        activeCount: count,
        onApply: _apply,
        onReset: _reset,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: const Icon(Icons.close_rounded, color: ExploreColors.textPrimary),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ExploreColors.textPrimary,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ExploreColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      centerTitle: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: ExploreColors.border),
      ),
    );
  }
}

// ─── 1. Sắp xếp ──────────────────────────────────────────────────────────────

class _SortSection extends StatelessWidget {
  const _SortSection({required this.current, required this.onSelect});

  final ExploreFilter current;
  final ValueChanged<ExploreFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Sắp xếp theo',
      icon: Icons.swap_vert_rounded,
      child: Column(
        children: [
          _RadioTile(
            icon: Icons.schedule_rounded,
            label: 'Mới nhất',
            subtitle: 'Bài viết được đăng gần đây nhất',
            isActive: current == ExploreFilter.newest,
            onTap: () => onSelect(ExploreFilter.newest),
          ),
          const _TileDivider(),
          _RadioTile(
            icon: Icons.trending_up_rounded,
            label: 'Xem nhiều nhất',
            subtitle: 'Bài viết có lượt xem cao nhất',
            isActive: current == ExploreFilter.mostViewed,
            onTap: () => onSelect(ExploreFilter.mostViewed),
          ),
          const _TileDivider(),
          _RadioTile(
            icon: Icons.star_rounded,
            label: 'Đánh giá cao nhất',
            subtitle: 'Điểm đánh giá trung bình cao nhất',
            isActive: current == ExploreFilter.topRated,
            onTap: () => onSelect(ExploreFilter.topRated),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Đánh giá ─────────────────────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.current, required this.onSelect});

  final double? current;
  final ValueChanged<double?> onSelect;

  static const _options = [3.0, 3.5, 4.0, 4.5];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Đánh giá',
      icon: Icons.star_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hiển thị bài viết có đánh giá từ:',
              style: TextStyle(
                fontSize: 13,
                color: ExploreColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RatingChip(
                  label: 'Tất cả',
                  stars: null,
                  isActive: current == null,
                  onTap: () => onSelect(null),
                ),
                ..._options.map(
                  (r) => _RatingChip(
                    label: '$r trở lên',
                    stars: r,
                    isActive: current == r,
                    onTap: () => onSelect(current == r ? null : r),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.stars,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final double? stars;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ExploreColors.chipActiveBg : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? ExploreColors.primary : ExploreColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stars != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: isActive
                      ? ExploreColors.primary
                      : const Color(0xFFFBBF24),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? ExploreColors.primary
                    : ExploreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. Tỉnh/Thành phố ───────────────────────────────────────────────────────

class _CitySection extends StatefulWidget {
  const _CitySection({
    required this.selectedCities,
    required this.onToggleCity,
  });

  final Set<String> selectedCities;
  final ValueChanged<String> onToggleCity;

  @override
  State<_CitySection> createState() => _CitySectionState();
}

class _CitySectionState extends State<_CitySection> {
  // null = Tất cả, hoặc 'north'/'central'/'south'
  String? _regionFilter;

  List<ExploreCityOption> get _visible {
    if (_regionFilter == null) return kPopularCities;
    return kPopularCities.where((c) => c.region == _regionFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Tỉnh/Thành phố du lịch',
      icon: Icons.location_city_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab lọc khu vực bên trong city section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _RegionTabChip(
                    label: 'Tất cả',
                    isActive: _regionFilter == null,
                    onTap: () => setState(() => _regionFilter = null),
                  ),
                  const SizedBox(width: 6),
                  _RegionTabChip(
                    label: 'Miền Bắc',
                    isActive: _regionFilter == 'north',
                    onTap: () => setState(() =>
                        _regionFilter = _regionFilter == 'north' ? null : 'north'),
                  ),
                  const SizedBox(width: 6),
                  _RegionTabChip(
                    label: 'Miền Trung',
                    isActive: _regionFilter == 'central',
                    onTap: () => setState(() => _regionFilter =
                        _regionFilter == 'central' ? null : 'central'),
                  ),
                  const SizedBox(width: 6),
                  _RegionTabChip(
                    label: 'Miền Nam',
                    isActive: _regionFilter == 'south',
                    onTap: () => setState(() =>
                        _regionFilter = _regionFilter == 'south' ? null : 'south'),
                  ),
                ],
              ),
            ),
          ),
          // Grid thành phố
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _visible.map((city) {
                final isSelected = widget.selectedCities.contains(city.slug);
                return _CityChip(
                  city: city,
                  isSelected: isSelected,
                  onTap: () => widget.onToggleCity(city.slug),
                );
              }).toList(),
            ),
          ),
          if (widget.selectedCities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Đã chọn ${widget.selectedCities.length} thành phố',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ExploreColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RegionTabChip extends StatelessWidget {
  const _RegionTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? ExploreColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : ExploreColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final ExploreCityOption city;
  final bool isSelected;
  final VoidCallback onTap;

  static const _regionAccent = {
    'north': Color(0xFF3B82F6),
    'central': Color(0xFFF59E0B),
    'south': Color(0xFF10B981),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _regionAccent[city.region] ?? ExploreColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : ExploreColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.check_circle_rounded, size: 14, color: accent),
              ),
            Text(
              city.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : ExploreColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 4. Mức giá ───────────────────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.selected, required this.onToggle});

  final Set<ExplorePriceFilter> selected;
  final ValueChanged<ExplorePriceFilter> onToggle;

  static const _priceColors = {
    ExplorePriceFilter.budget: Color(0xFF10B981),
    ExplorePriceFilter.mid: Color(0xFF3B82F6),
    ExplorePriceFilter.high: Color(0xFFF59E0B),
    ExplorePriceFilter.luxury: Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Mức chi phí',
      icon: Icons.payments_outlined,
      child: Column(
        children: ExplorePriceFilter.values.map((pf) {
          final isLast = pf == ExplorePriceFilter.values.last;
          final accent = _priceColors[pf]!;
          return Column(
            children: [
              _CheckboxTile(
                symbol: pf.symbol,
                label: pf.labelVi,
                isActive: selected.contains(pf),
                accentColor: accent,
                onTap: () => onToggle(pf),
              ),
              if (!isLast) const _TileDivider(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.activeCount,
    required this.onApply,
    required this.onReset,
  });

  final int activeCount;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: ExploreColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ExploreColors.textSecondary,
                  side: const BorderSide(color: ExploreColors.border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Đặt lại',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ExploreColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    activeCount > 0
                        ? 'Áp dụng ($activeCount bộ lọc)'
                        : 'Áp dụng',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared building blocks ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ExploreColors.chipActiveBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: ExploreColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: ExploreColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ExploreColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: isActive
            ? ExploreColors.chipActiveBg.withAlpha(80)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? ExploreColors.primary.withAlpha(25)
                    : const Color(0xFFEEF2F5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isActive ? ExploreColors.primary : ExploreColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? ExploreColors.primary
                          : ExploreColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: ExploreColors.textMuted),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? ExploreColors.primary : ExploreColors.border,
                  width: 2,
                ),
                color: isActive ? ExploreColors.primary : Colors.transparent,
              ),
              child: isActive
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({
    required this.symbol,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final String symbol;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: isActive ? accentColor.withAlpha(15) : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor.withAlpha(25)
                    : const Color(0xFFEEF2F5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isActive ? accentColor : ExploreColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? ExploreColors.textPrimary
                      : ExploreColors.textSecondary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? accentColor : ExploreColors.border,
                  width: 2,
                ),
                color: isActive ? accentColor : Colors.transparent,
              ),
              child: isActive
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: ExploreColors.border,
      );
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 24);
}
