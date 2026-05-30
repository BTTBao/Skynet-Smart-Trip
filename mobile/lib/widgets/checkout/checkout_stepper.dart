import 'package:flutter/material.dart';

class CheckoutStepper extends StatelessWidget {
  final int currentStep; // 1, 2, or 3

  const CheckoutStepper({Key? key, required this.currentStep}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStepColumn('BƯỚC 1', 'Chọn', 1),
            _buildStepColumn('BƯỚC 2', 'Thông tin', 2),
            _buildStepColumn('BƯỚC 3', 'Thanh toán', 3),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildProgressBar(1)),
            const SizedBox(width: 4),
            Expanded(child: _buildProgressBar(2)),
            const SizedBox(width: 4),
            Expanded(child: _buildProgressBar(3)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepColumn(String stepText, String title, int stepIndex) {
    final bool isCurrent = stepIndex == currentStep;
    final bool isCompleted = stepIndex < currentStep;
    final Color color = isCurrent || isCompleted ? Colors.green[400]! : Colors.grey[400]!;

    return Column(
      children: [
        Text(
          stepText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? Colors.black : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int stepIndex) {
    final bool isActive = stepIndex <= currentStep;
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? Colors.green[400] : Colors.green[50],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
