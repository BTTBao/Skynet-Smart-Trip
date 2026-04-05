import 'package:flutter/material.dart';
// 1. IMPORT FILE HOME_VIEW CỦA BẠN VÀO ĐÂY
import 'views/home_view.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      // Tắt cái dải băng đỏ chữ "Debug" ở góc trên bên phải cho đẹp
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        // Đổi seedColor sang màu xanh lá cho tone-sur-tone với app du lịch
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // 2. GẮN HOMEVIEW Ở ĐÂY ĐỂ NÓ CHẠY ĐẦU TIÊN
      home: const HomeView(), 
    );
  }
}