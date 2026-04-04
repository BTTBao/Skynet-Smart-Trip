import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/main_shell.dart';
import 'providers/providers.dart';
import 'views/resort_detail/resort_detail_screen.dart'; // Import trang test mới

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skynet Smart Trip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF80ed99)),
        useMaterial3: true,
        fontFamily: 'Public Sans',
      ),
      // Mở/tắt comment (Ctrl + /) 1 trong 2 dòng dưới đây để chuyển qua lại:
      home: const ResortDetailScreen(),   // Đang chạy trang Resort Detail
      // home: const MainShell(),         // Trang cũ của app
    );
  }
}

