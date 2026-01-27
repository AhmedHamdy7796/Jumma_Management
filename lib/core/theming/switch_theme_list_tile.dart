import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/core/theming/theme_cubit.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

class SwitchThemeListTile extends StatelessWidget {
  const SwitchThemeListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        bool isDark = themeMode == ThemeMode.dark;
        return ListTile(
          leading: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).primaryColor,
          ),
          title: const Text(
            AppStrings.theme,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
            ),
          ),
          trailing: Switch(
            value: isDark,
            onChanged: (value) {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
          onTap: () {
            context.read<ThemeCubit>().toggleTheme();
          },
        );
      },
    );
  }
}
