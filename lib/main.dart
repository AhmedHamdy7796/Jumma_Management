import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'core/resources/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/routes/routes.dart';
import 'core/theming/app_theme_data.dart';
import 'core/theming/theme_cubit.dart';
import 'features/customer/presentation/cubit/customer_cubit.dart';
import 'features/fix/presentation/cubit/fix_cubit.dart';
import 'features/purchase/presentation/cubit/purchase_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeDesktop();

  runApp(MyApp());
}

Future<void> _initializeDesktop() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize sqflite for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Initialize window_manager for desktop UI enhancements
    await windowManager.ensureInitialized();
    const WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppStrings.appTitle,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

class MyApp extends StatelessWidget {
  final AppRouter _appRouter = AppRouter();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CustomerCubit()..loadCustomers()),
        BlocProvider(create: (_) => PurchaseCubit()..loadPurchases()),
        BlocProvider(create: (_) => FixCubit()..loadFixes()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppStrings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            themeMode: themeMode,
            onGenerateRoute: _appRouter.onGenerateRoute,
            initialRoute: Routes.splash,
          );
        },
      ),
    );
  }
}
