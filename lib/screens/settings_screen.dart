import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(profile),
          const SizedBox(height: 24),
          _buildSectionTitle('Preferences'),
          const SizedBox(height: 8),
          _buildThemeToggle(themeProvider),
          const Divider(height: 1),
          _buildSmsAutoReadToggle(authProvider),
          const Divider(height: 1),
          _buildNotificationToggle(authProvider),
          const Divider(height: 1),
          _buildBudgetAlertToggle(authProvider),
          const SizedBox(height: 24),
          _buildSectionTitle('Support'),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version ${AppConstants.appVersion}',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          _buildSignOutButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileSection(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider) {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      subtitle: const Text('Toggle dark theme'),
      secondary: Icon(
        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: AppColors.primary,
      ),
      value: themeProvider.isDarkMode,
      onChanged: (_) => themeProvider.toggleTheme(),
    );
  }

  Widget _buildSmsAutoReadToggle(AuthProvider authProvider) {
    return SwitchListTile(
      title: const Text('Auto-read SMS'),
      subtitle: const Text('Detect transactions from SMS'),
      secondary: const Icon(Icons.sms, color: AppColors.primary),
      value: authProvider.userProfile?.smsAutoRead ?? false,
      onChanged: (value) {
        final profile = authProvider.userProfile;
        if (profile != null) {
          authProvider.updateProfile(profile.copyWith(smsAutoRead: value));
        }
      },
    );
  }

  Widget _buildNotificationToggle(AuthProvider authProvider) {
    return SwitchListTile(
      title: const Text('Push Notifications'),
      subtitle: const Text('Receive transaction alerts'),
      secondary: const Icon(Icons.notifications_outlined,
          color: AppColors.primary),
      value: authProvider.userProfile?.pushNotifications ?? true,
      onChanged: (value) {
        final profile = authProvider.userProfile;
        if (profile != null) {
          authProvider.updateProfile(
              profile.copyWith(pushNotifications: value));
        }
      },
    );
  }

  Widget _buildBudgetAlertToggle(AuthProvider authProvider) {
    return SwitchListTile(
      title: const Text('Budget Alerts'),
      subtitle: const Text('Get notified when nearing budget limit'),
      secondary: const Icon(Icons.trending_up, color: AppColors.primary),
      value: authProvider.userProfile?.budgetAlerts ?? true,
      onChanged: (value) {
        final profile = authProvider.userProfile;
        if (profile != null) {
          authProvider.updateProfile(
              profile.copyWith(budgetAlerts: value));
        }
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmSignOut(context),
      icon: const Icon(Icons.logout, color: AppColors.danger),
      label: const Text(
        'Sign Out',
        style: TextStyle(color: AppColors.danger),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.danger),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
