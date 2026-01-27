import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/core/routes/app_router.dart';
import 'package:gomaa_management/core/routes/routes.dart';
import 'package:gomaa_management/core/theming/app_theme_data.dart';
import 'package:gomaa_management/core/theming/theme_cubit.dart';
import 'features/customer/presentation/cubit/customer_cubit.dart';
import 'features/purchase/presentation/cubit/purchase_cubit.dart';
import 'features/fix/presentation/cubit/fix_cubit.dart';
import 'core/resources/app_strings.dart';

void main() {
  runApp(MyApp());
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
