import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/resources/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/routes/routes.dart';
import 'core/theming/app_theme_data.dart';
import 'core/theming/theme_cubit.dart';
import 'core/logging/app_logger.dart';

// DI Repositories
import 'repositories/customer_repository.dart';
import 'repositories/purchase_repository.dart';
import 'repositories/fix_repository.dart';
import 'repositories/inventory_repository.dart';
import 'repositories/sales_invoice_repository.dart';
import 'repositories/maintenance_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/audit_log_repository.dart';
import 'repositories/search_repository.dart';

// DI Cubits
import 'cubits/customer/customer_cubit.dart';
import 'cubits/purchase/purchase_cubit.dart';
import 'cubits/fix/fix_cubit.dart';
import 'cubits/inventory/inventory_cubit.dart';
import 'cubits/sales_invoice/sales_invoice_cubit.dart';
import 'cubits/maintenance/maintenance_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'cubits/backup/backup_cubit.dart';
import 'cubits/audit_log/audit_log_cubit.dart';
import 'cubits/search/search_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize daily file logger first
  await AppLogger.instance.initialize();

  await _initializeDesktop();

  runApp(MyApp());
}

Future<void> _initializeDesktop() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

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

  // Shared repository instances for Dependency Injection
  final customerRepo = CustomerRepository();
  final purchaseRepo = PurchaseRepository();
  final fixRepo = FixRepository();
  final inventoryRepo = InventoryRepository();
  final salesInvoiceRepo = SalesInvoiceRepository();
  final maintenanceRepo = MaintenanceRepository();
  final settingsRepo = SettingsRepository();
  final auditLogRepo = AuditLogRepository();
  final searchRepo = SearchRepository();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CustomerCubit(customerRepo)..loadCustomers()),
        BlocProvider(create: (_) => PurchaseCubit(purchaseRepo)..loadPurchases()),
        BlocProvider(create: (_) => FixCubit(fixRepo)..loadFixes()),
        BlocProvider(create: (_) => InventoryCubit(inventoryRepo)..loadInventory()),
        BlocProvider(create: (_) => SalesInvoiceCubit(salesInvoiceRepo)..loadAll()),
        BlocProvider(create: (_) => MaintenanceCubit(maintenanceRepo)..loadMaintenanceData()),
        BlocProvider(create: (_) => SettingsCubit(settingsRepo)..loadSettings()),
        BlocProvider(create: (_) => AuditLogCubit(auditLogRepo)),
        BlocProvider(create: (_) => SearchCubit(searchRepo)),
        BlocProvider(create: (_) => BackupCubit()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp(
                title: AppStrings.appTitle,
                debugShowCheckedModeBanner: false,
                theme: AppThemeData.lightTheme,
                darkTheme: AppThemeData.darkTheme,
                themeMode: themeMode,
                locale: const Locale('ar', ''),
                supportedLocales: const [
                  Locale('ar', ''),
                  Locale('en', ''),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
                onGenerateRoute: _appRouter.onGenerateRoute,
                initialRoute: Routes.splash,
              );
            },
          );
        },
      ),
    );
  }
}
