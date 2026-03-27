import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

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
          'Dịch vụ yêu thích',
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
          icon: Icons.favorite_outline,
          title: 'Chưa có yêu thích',
          subtitle: 'Hãy khám phá các chuyến đi tuyệt vời và lưu lại những dịch vụ mà bạn yêu thích nhất nhé!',
          buttonText: 'Khám phá ngay',
        ),
      ),
    );
  }
}
