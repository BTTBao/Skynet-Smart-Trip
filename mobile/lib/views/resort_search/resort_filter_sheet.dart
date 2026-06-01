import 'package:flutter/material.dart';

class ResortFilterSheet extends StatefulWidget {
  const ResortFilterSheet({Key? key}) : super(key: key);

  @override
  State<ResortFilterSheet> createState() => _ResortFilterSheetState();
}

class _ResortFilterSheetState extends State<ResortFilterSheet> {
  int _sortIndex = 0; // 0: Phổ biến, 1: Giá thấp, 2: Gần tôi
  RangeValues _priceRange = const RangeValues(500000, 5000000);
  int _starIndex = 1; // 0=3*, 1=4*, 2=5*, 3=Cao cap

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bộ lọc & Sắp xếp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton(onPressed: () {}, child: const Text('Thiết lập lại', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(Icons.sort, 'Sắp xếp theo'),
              const SizedBox(height: 16),
              _buildRadioOption('Phổ biến nhất', 0),
              const SizedBox(height: 12),
              _buildRadioOption('Giá thấp đến cao', 1),
              const SizedBox(height: 12),
              _buildRadioOption('Gần tôi nhất', 2),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(Icons.money, 'Khoảng giá (VND)'),
                  const Text('500k - 5tr+', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.deepOrange,
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                  overlayColor: Colors.deepOrange.withOpacity(0.2),
                ),
                child: RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 10000000,
                  onChanged: (RangeValues values) {
                    setState(() { _priceRange = values; });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildPriceBox('Tối thiểu', '500.000đ')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPriceBox('Tối đa', '5.000.000đ')),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(Icons.star, 'Hạng sao'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStarBox('3', 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStarBox('4', 1)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStarBox('5', 2)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStarBox('Cao cấp', 3)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, color: Colors.black, size: 20),
                  label: const Text('Áp dụng bộ lọc', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DE899),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildRadioOption(String title, int index) {
    bool isSelected = _sortIndex == index;
    return GestureDetector(
      onTap: () { setState(() { _sortIndex = index; }); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15)),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey[400]!, width: 2),
              ),
              child: isSelected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle))) : null,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStarBox(String star, int index) {
    bool isSelected = _starIndex == index;
    return GestureDetector(
      onTap: () { setState(() { _starIndex = index; }); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(star, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.deepOrange : Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ),
      ),
    );
  }
}
