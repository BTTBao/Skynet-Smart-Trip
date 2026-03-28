import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';

class ActivityHistoryView extends StatelessWidget {
  const ActivityHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: EmptyStatePlaceholder(
          icon: Icons.history,
          title: 'Lịch sử trống',
          subtitle: 'Bạn chưa có hoạt động nào gần đây. Bắt đầu chuyến đi đầu tiên của mình ngay hôm nay!',
          buttonText: 'Lên kế hoạch ngay',
        ),
      ),
    );
  }
}
