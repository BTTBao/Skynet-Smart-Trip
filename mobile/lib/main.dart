import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'views/auth/splash_screen.dart';
import 'providers/providers.dart';
import 'views/resort_detail/resort_detail_screen.dart'; // Import trang test mới
import 'providers/auth_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(
          create: (_) => DestinationProvider()..fetchDestinations(),
        ),
        ChangeNotifierProvider(
          create: (_) => HotelProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BusProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider()..initialize(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      title: 'Skynet Smart Trip',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      locale: appSettings.locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: appSettings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF80ed99),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bgPage,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textHeading,
        ),
        cardColor: AppColors.bgCard,
        useMaterial3: true,
        fontFamily: 'Public Sans',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF80ed99),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF111827),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Public Sans',
      ),

      // Mở/tắt comment (Ctrl + /) 1 trong 2 dòng dưới đây để chuyển qua lại:
      // home: const ResortDetailScreen(),   // Đang chạy trang Resort Detail
      home: const MainShell(),         // Trang cũ của app

      // home: const SplashScreen(),

    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}