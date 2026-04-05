import 'package:flutter/material.dart';
// 1. IMPORT FILE HOME_VIEW CỦA BẠN VÀO ĐÂY
import 'views/home_view.dart'; 
import 'package:provider/provider.dart';
import 'views/main_shell.dart';
import 'providers/providers.dart';

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
      home: const MainShell(),
    );
  }
}