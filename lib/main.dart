import 'dart:io';
import 'dart:ui';

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
import 'repositories/machine_repository.dart';
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
import 'cubits/machine/machine_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'cubits/backup/backup_cubit.dart';
import 'cubits/audit_log/audit_log_cubit.dart';
import 'cubits/search/search_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize daily file logger first
  await AppLogger.instance.initialize();

  // Global safety net: Log errors to rotating log file and provide friendly UI fallback
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.instance.error(
      'FlutterError: ${details.exceptionAsString()}',
      tag: 'GlobalSafetyNet',
      exception: details.exception,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.instance.error(
      'PlatformDispatcher error: $error',
      tag: 'GlobalSafetyNet',
      exception: error,
    );
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.warning_amber_rounded, size: 56, color: Colors.amber),
              SizedBox(height: 12),
              Text(
                'عذراً، حدث خطأ غير متوقع في العرض',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'تم تسجيل الخطأ في السجل تلقائياً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

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
  final machineRepo = MachineRepository();
  final settingsRepo = SettingsRepository();
  final auditLogRepo = AuditLogRepository();
  final searchRepo = SearchRepository();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryCubit = InventoryCubit(inventoryRepo)..loadInventory();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CustomerCubit(customerRepo)..loadCustomers()),
        BlocProvider<InventoryCubit>.value(value: inventoryCubit),
        BlocProvider(
          create: (_) => PurchaseCubit(
            purchaseRepo,
            onInventoryChanged: () => inventoryCubit.loadInventory(),
          )..loadPurchases(),
        ),
        BlocProvider(create: (_) => FixCubit(fixRepo)..loadFixes()),
        BlocProvider(
          create: (_) => SalesInvoiceCubit(
            salesInvoiceRepo,
            onInventoryChanged: () => inventoryCubit.loadInventory(),
          )..loadAll(),
        ),
        BlocProvider(create: (_) => MaintenanceCubit(maintenanceRepo)..loadMaintenanceData()),
        BlocProvider(create: (_) => MachineCubit(machineRepo)..loadAll()),
        BlocProvider(create: (_) => SettingsCubit(settingsRepo)..loadSettings()),
        BlocProvider(create: (_) => AuditLogCubit(auditLogRepo)),
        BlocProvider(create: (_) => SearchCubit(searchRepo)),
        BlocProvider(create: (ctx) => BackupCubit(
          onRestoreComplete: () {
            // Reload every global cubit so the UI reflects the restored data.
            if (ctx.mounted) {
              ctx.read<CustomerCubit>().loadCustomers();
              ctx.read<PurchaseCubit>().loadPurchases();
              ctx.read<FixCubit>().loadFixes();
              ctx.read<InventoryCubit>().loadInventory();
              ctx.read<SalesInvoiceCubit>().loadAll();
              ctx.read<MaintenanceCubit>().loadMaintenanceData();
              ctx.read<MachineCubit>().loadAll();
              ctx.read<SettingsCubit>().loadSettings();
            }
          },
        )),
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
