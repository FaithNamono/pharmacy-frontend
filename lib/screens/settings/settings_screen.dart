// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/backup_provider.dart';
import '../../models/theme_model.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backupProvider = Provider.of<BackupProvider>(context, listen: false);
      backupProvider.checkAutoBackup();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<SettingsProvider, BackupProvider>(
        builder: (context, settingsProvider, backupProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              _buildSectionHeader('Profile Information'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.veryLightGreen,
                        child: Text(
                          user?.initials ?? 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? 'User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (user?.phone != null && user!.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.phone!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Account Security
              _buildSectionHeader('Account Security'),
              _buildAccountTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Last changed: ${user?.lastPasswordChange ?? 'Never'}',
                onTap: () => _showChangePasswordDialog(context, authProvider),
              ),

              const SizedBox(height: 16),

              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildThemeSelector(settingsProvider),

              const SizedBox(height: 16),

              // Data & Backup
              _buildSectionHeader('Data & Backup'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  secondary: const Icon(Icons.backup_outlined),
                  title: Text(
                    'Auto Backup',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    backupProvider.autoBackupEnabled 
                        ? 'Last backup: ${backupProvider.lastBackupTime != null ? _formatDate(DateTime.parse(backupProvider.lastBackupTime!)) : 'Never'}\nNext backup: ${backupProvider.nextBackupTime}'
                        : 'Enable automatic daily backups at 2 AM',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  value: backupProvider.autoBackupEnabled,
                  onChanged: (value) async {
                    await backupProvider.toggleAutoBackup(value);
                    if (mounted && value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Auto-backup enabled. Backups will run daily at 2 AM'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  activeColor: AppColors.primaryGreen,
                ),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.backup, color: AppColors.primaryGreen),
                  title: Text(
                    'Backup Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    backupProvider.lastBackupInfo,
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  trailing: backupProvider.isBackingUp
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: backupProvider.isBackingUp ? null : () => _performBackup(context, backupProvider),
                ),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: Text(
                    'Restore Data',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Restore from previous backup (${backupProvider.backupHistory.length} available)',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  trailing: backupProvider.isRestoring
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: backupProvider.isRestoring ? null : () => _showRestoreDialog(context, backupProvider),
                ),
              ),
              if (backupProvider.backupLocation.isNotEmpty && backupProvider.backupLocation != 'Backup not available on web')
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Backup Location: ${backupProvider.backupLocation}',
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // About Section
              _buildSectionHeader('About'),
              _buildAboutTile(
                icon: Icons.info_outline,
                title: 'App Information',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAppInfoDialog(context),
              ),
              _buildAboutTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () => _showTermsDialog(context),
              ),
              _buildAboutTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _showPrivacyDialog(context),
              ),
              _buildAboutTile(
                icon: Icons.security,
                title: 'Security & Compliance',
                subtitle: 'Security measures and certifications',
                onTap: () => _showSecurityDialog(context),
              ),
              _buildAboutTile(
                icon: Icons.support_agent,
                title: 'Support & Help',
                subtitle: 'Get assistance',
                onTap: () => _showSupportDialog(context),
              ),
              _buildAboutTile(
                icon: Icons.code,
                title: 'Open Source Licenses',
                subtitle: 'Third-party licenses',
                onTap: () => _showLicensesDialog(context),
              ),

              const SizedBox(height: 24),

              // Logout Button
              CustomButton(
                text: 'LOGOUT',
                onPressed: () async {
                  final confirm = await _showLogoutDialog(context);
                  if (confirm) {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                color: Colors.red,
                isFullWidth: true,
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(SettingsProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: AppTheme.values.map((theme) {
          return Column(
            children: [
              ListTile(
                leading: Icon(theme.icon),
                title: Text(
                  theme.displayName,
                  style: GoogleFonts.poppins(),
                ),
                trailing: provider.currentTheme == theme
                    ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  provider.setTheme(theme);
                },
              ),
              if (theme != AppTheme.values.last) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD DIALOG - WITH EYE ICONS AND WORKING API
  // ============================================================

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  showDialog(
    context: context,
    barrierDismissible: false,  // ✅ Prevent dismissing while loading
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrent = !_obscureCurrent;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureCurrent,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNew = !_obscureNew;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureNew,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirm,
                ),
                const SizedBox(height: 8),
                Text(
                  'Password must be at least 6 characters',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                // Show loading indicator
                setState(() {
                  // This will rebuild the dialog with loading state if needed
                });
                
                // Call the API
                final success = await authProvider.updatePassword(currentPassword, newPassword);
                
                if (success && mounted) {
                  // Close the dialog
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.error ?? 'Failed to change password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    ),
  );
}

  // ============================================================
  // ALL OTHER DIALOGS
  // ============================================================

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('App Name', 'Dervin Pharmacy'),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '2024.03.11'),
            _buildInfoRow('Flutter', '3.16.0'),
            _buildInfoRow('Dart', '3.2.0'),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '© 2026 Dervin Pharmacy. All rights reserved.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: March 11, 2024',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildSection('1. Acceptance of Terms', 
                  'By accessing and using Dervin Pharmacy Management System, you agree to be bound by these Terms of Service.'),
                _buildSection('2. User Accounts', 
                  '• You are responsible for maintaining the confidentiality of your account\n'
                  '• You are responsible for all activities under your account\n'
                  '• You must notify us immediately of any unauthorized use\n'
                  '• We reserve the right to terminate accounts for violations'),
                _buildSection('3. Data Accuracy', 
                  'You are responsible for ensuring the accuracy of all data entered into the system, including medicine information, sales records and inventory counts.'),
                _buildSection('4. Prohibited Activities', 
                  '• Selling expired or counterfeit medicines\n'
                  '• Manipulating inventory records\n'
                  '• Unauthorized access to other accounts\n'
                  '• Using the system for illegal purposes'),
                _buildSection('5. Limitation of Liability', 
                  'Dervin Pharmacy shall not be liable for any indirect, incidental, or consequential damages arising from the use of this system.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: March 11, 2024',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildSection('Information We Collect', 
                  '• Personal information (name, email, phone)\n'
                  '• Login credentials (encrypted)\n'
                  '• Pharmacy inventory and sales data\n'
                  '• Usage statistics and preferences'),
                _buildSection('How We Use Your Information', 
                  '• To provide and maintain our service\n'
                  '• To notify you about changes\n'
                  '• To provide customer support\n'
                  '• To gather analysis for improvement'),
                _buildSection('Data Security', 
                  'We implement industry-standard security measures including encryption, secure authentication and regular security audits to protect your data.'),
                _buildSection('Data Retention', 
                  'We retain your data for as long as your account is active. You may request data deletion by contacting support.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security & Compliance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Encryption', 'AES-256'),
            _buildInfoRow('Authentication', 'Token-based'),
            _buildInfoRow('Session Timeout', '30 minutes'),
            _buildInfoRow('Password Policy', 'Minimum 8 characters'),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Compliance Standards:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const Text('• HIPAA compliant data handling'),
            const Text('• GDPR compliant'),
            const Text('• Local data storage only'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support & Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactRow(Icons.email, 'Email Support', 'dervinpharmacy7@gmail.com'),
            _buildContactRow(Icons.phone, 'Phone Support', '+256 741 910 668'),
            _buildContactRow(Icons.access_time, 'Support Hours', 'Monday - Friday, 9AM - 5PM'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For technical support, please email us with your issue and we will respond within 24 hours.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Source Licenses'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildLicenseTile('Flutter SDK', 'BSD 3-Clause'),
              _buildLicenseTile('Provider Package', 'MIT'),
              _buildLicenseTile('Shared Preferences', 'BSD 3-Clause'),
              _buildLicenseTile('Google Fonts', 'MIT'),
              _buildLicenseTile('URL Launcher', 'BSD 3-Clause'),
              _buildLicenseTile('Path Provider', 'BSD 3-Clause'),
              _buildLicenseTile('SQFlite', 'BSD 3-Clause'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTile(String name, String license) {
    return ListTile(
      title: Text(name, style: const TextStyle(fontSize: 14)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          license,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Future<void> _performBackup(BuildContext context, BackupProvider backupProvider) async {
    final shouldBackup = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will backup:'),
            const SizedBox(height: 8),
            const Text('• App settings and preferences', style: TextStyle(fontSize: 13)),
            const Text('• User preferences', style: TextStyle(fontSize: 13)),
            const Text('• System configuration', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Text(
              'Backup will be saved to: ${backupProvider.backupLocation}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BACKUP'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldBackup) {
      final success = await backupProvider.performBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Backup completed successfully!' : 'Backup failed: ${backupProvider.error}'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context, BackupProvider backupProvider) async {
    final backups = await backupProvider.getAvailableBackups();
    
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backups found'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Column(
            children: [
              const Text('Select a backup to restore:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    return ListTile(
                      leading: Icon(backup['auto_backup'] == true ? Icons.schedule : Icons.backup),
                      title: Text(backup['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(backup['date']),
                          Text(backup['size'], style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pop(context, backup),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ Warning: Restoring will overwrite current settings',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    ).then((selectedBackup) async {
      if (selectedBackup != null && mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Restore'),
            content: const Text('This will replace current settings. Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('RESTORE'),
              ),
            ],
          ),
        ) ?? false;
        
        if (confirm) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restoring data...'),
              ],
            )),
          );
          
          final success = await backupProvider.restoreBackup(selectedBackup['path']);
          
          Navigator.pop(context);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Settings restored successfully!' : 'Restore failed: ${backupProvider.error}'),
                backgroundColor: success ? Colors.green : Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            if (success) {
              setState(() {});
            }
          }
        }
      }
    });
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}