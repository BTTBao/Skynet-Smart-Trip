import 'package:flutter/material.dart';
import '../../widgets/checkout/checkout_stepper.dart';
import 'customer_info_screen.dart';

class BookingDateGuestScreen extends StatefulWidget {
  const BookingDateGuestScreen({Key? key}) : super(key: key);

  @override
  State<BookingDateGuestScreen> createState() => _BookingDateGuestScreenState();
}

class _BookingDateGuestScreenState extends State<BookingDateGuestScreen> {
  int adultCount = 2;
  int childCount = 0;
  int infantCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn ngày & Khách',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const CheckoutStepper(currentStep: 1),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCalendarWidget(),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Số lượng khách',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildGuestCounter('Người lớn', 'Từ 13 tuổi trở lên', adultCount, (val) => setState(() => adultCount = val)),
                    const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
                    _buildGuestCounter('Trẻ em', 'Độ tuổi 2 - 12', childCount, (val) => setState(() => childCount = val)),
                    const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
                    _buildGuestCounter('Em bé', 'Dưới 2 tuổi', infantCount, (val) => setState(() => infantCount = val)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0), // Nền xanh nhạt
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(color: Color(0xFF6DE899), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.info_outline, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Giá phòng có thể thay đổi tùy thuộc vào ngày bạn chọn và số lượng khách thực tế. Hãy đảm bảo thông tin chính xác.',
                        style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // A simplified static mock matching the visual provided
  Widget _buildCalendarWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.chevron_left, color: Colors.black),
              const Text('Tháng 11 2023', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
          const SizedBox(height: 24),
          // Days of week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('T2', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T3', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T4', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T5', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T6', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T7', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('CN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          // Grid of dates (Mock)
          Column(
            children: [
              // Row 1
              Row(
                children: [
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                  Expanded(child: _buildDateCell('1', '850k', false)),
                  Expanded(child: _buildDateCell('2', '850k', false)),
                  Expanded(child: _buildDateCell('3', '1.2tr', true, isStart: true)),
                  Expanded(child: _buildDateCell('4', '1.2tr', true, isMiddle: true)),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2
              Row(
                children: [
                  Expanded(child: _buildDateCell('5', '1.2tr', true, isEnd: true)),
                  Expanded(child: _buildDateCell('6', '850k', false)),
                  Expanded(child: _buildDateCell('7', '850k', false)),
                  Expanded(child: _buildDateCell('8', '850k', false)),
                  Expanded(child: _buildDateCell('9', 'Hết', false, isUnavailable: true)),
                  Expanded(child: _buildDateCell('10', '900k', false)),
                  Expanded(child: _buildDateCell('11', '1.5tr', false)),
                ],
              ),
              const SizedBox(height: 8),
              // Row 3
              Row(
                children: [
                  Expanded(child: _buildDateCell('12', '1.5tr', false)),
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                  Expanded(child: const SizedBox()),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDateCell(String date, String price, bool isSelected, {bool isStart = false, bool isEnd = false, bool isMiddle = false, bool isUnavailable = false}) {
    Color bgColor = Colors.transparent;
    BorderRadius? borderRadius;
    Color dateColor = Colors.black87;
    Color priceColor = Colors.grey[500]!;

    if (isSelected) {
      if (isStart) {
        bgColor = const Color(0xFF6DE899); // Dark green
        borderRadius = const BorderRadius.horizontal(left: Radius.circular(8));
        dateColor = Colors.black;
        priceColor = Colors.black87;
      } else if (isEnd) {
        bgColor = const Color(0xFF6DE899); // Dark green
        borderRadius = const BorderRadius.horizontal(right: Radius.circular(8));
        dateColor = Colors.black;
        priceColor = Colors.black87;
      } else if (isMiddle) {
        bgColor = const Color(0xFFD4F8E5); // Light green
        dateColor = Colors.black87;
        priceColor = Colors.grey[600]!;
      }
    }

    if (isUnavailable) {
      dateColor = Colors.grey[400]!;
      priceColor = Colors.grey[300]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: dateColor,
              decoration: isUnavailable ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: TextStyle(
              fontSize: 10,
              color: priceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCounter(String title, String subtitle, int count, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (count > 0) onChanged(count - 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green[100]!),
                    color: Colors.white,
                  ),
                  child: const Center(child: Icon(Icons.remove, color: Colors.green, size: 16)),
                ),
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  onChanged(count + 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6DE899),
                  ),
                  child: const Center(child: Icon(Icons.add, color: Colors.white, size: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '1.700.000₫',
                      style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '-10%',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[500], size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '2 đêm / 2 người',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Chuyển sang Bước 2: Nhập thông tin khách hàng
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerInfoScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6DE899),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                elevation: 0,
              ),
              child: const Text('Tiếp tục', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
