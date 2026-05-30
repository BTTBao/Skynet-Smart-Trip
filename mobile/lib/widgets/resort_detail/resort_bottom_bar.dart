import 'package:flutter/material.dart';

class ResortBottomBar extends StatelessWidget {
  final double price;
  final VoidCallback onBookNow;

  const ResortBottomBar({
    Key? key,
    required this.price,
    required this.onBookNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = price.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
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
                const Text('Giá từ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                RichText(
                  text: TextSpan(
                    text: '$currencyFormatter₫',
                    style: TextStyle(
                      color: Colors.green[500],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    children: const [
                      TextSpan(
                        text: ' / đêm',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: onBookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Đặt ngay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
