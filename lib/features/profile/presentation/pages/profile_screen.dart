import 'package:flutter/material.dart';
import 'package:gomaa_management/core/theming/switch_theme_list_tile.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.profile,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 24),
          _buildSettingsSection(context),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              AppStrings.version,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'أحمد جمعة', // Placeholder or load from auth
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontFamily: 'Arial',
            ),
          ),
          Text(
            'ahmed@example.com', // Placeholder
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: AppStrings.language,
            trailing: const Text(
              'العربية',
              style: TextStyle(color: AppColors.primary),
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          const SwitchThemeListTile(),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: AppStrings.aboutApp,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontFamily: 'Arial',
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Logic for logout
        },
        icon: const Icon(Icons.logout),
        label: const Text(
          AppStrings.logout,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
