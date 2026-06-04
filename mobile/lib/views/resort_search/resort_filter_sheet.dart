import 'package:flutter/material.dart';

enum ResortSortOption { popular, priceLowToHigh, ratingHighToLow }

class ResortFilterResult {
  const ResortFilterResult({
    this.sort = ResortSortOption.popular,
    this.minPrice = 0,
    this.maxPrice = 10000000,
    this.minimumStars = 0,
    this.poolOnly = false,
  });

  final ResortSortOption sort;
  final double minPrice;
  final double maxPrice;
  final int minimumStars;
  final bool poolOnly;
}

class ResortFilterSheet extends StatefulWidget {
  const ResortFilterSheet({super.key, required this.initialValue});

  final ResortFilterResult initialValue;

  @override
  State<ResortFilterSheet> createState() => _ResortFilterSheetState();
}

class _ResortFilterSheetState extends State<ResortFilterSheet> {
  late ResortSortOption _sort;
  late RangeValues _priceRange;
  late int _minimumStars;
  late bool _poolOnly;

  @override
  void initState() {
    super.initState();
    _sort = widget.initialValue.sort;
    _priceRange = RangeValues(
      widget.initialValue.minPrice,
      widget.initialValue.maxPrice,
    );
    _minimumStars = widget.initialValue.minimumStars;
    _poolOnly = widget.initialValue.poolOnly;
  }

  void _reset() {
    setState(() {
      _sort = ResortSortOption.popular;
      _priceRange = const RangeValues(0, 10000000);
      _minimumStars = 0;
      _poolOnly = false;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      ResortFilterResult(
        sort: _sort,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        minimumStars: _minimumStars,
        poolOnly: _poolOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bo loc & sap xep',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Dat lai')),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Sap xep theo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile(
                value: ResortSortOption.popular,
                groupValue: _sort,
                onChanged: (value) => setState(() => _sort = value!),
                title: const Text('Pho bien nhat'),
              ),
              RadioListTile(
                value: ResortSortOption.priceLowToHigh,
                groupValue: _sort,
                onChanged: (value) => setState(() => _sort = value!),
                title: const Text('Gia thap den cao'),
              ),
              RadioListTile(
                value: ResortSortOption.ratingHighToLow,
                groupValue: _sort,
                onChanged: (value) => setState(() => _sort = value!),
                title: const Text('Danh gia cao nhat'),
              ),
              const SizedBox(height: 12),
              Text(
                'Khoang gia: ${_shortPrice(_priceRange.start)} - ${_shortPrice(_priceRange.end)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 10000000,
                divisions: 20,
                onChanged: (value) => setState(() => _priceRange = value),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hang sao toi thieu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Tat ca')),
                  ButtonSegment(value: 3, label: Text('3+')),
                  ButtonSegment(value: 4, label: Text('4+')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {_minimumStars},
                onSelectionChanged: (value) =>
                    setState(() => _minimumStars = value.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _poolOnly,
                onChanged: (value) => setState(() => _poolOnly = value),
                title: const Text('Chi hien khach san co ho boi'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check),
                  label: const Text('Ap dung bo loc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}tr';
    return '${(price / 1000).round()}k';
  }
}
