import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'push_notification_service.dart';

/// Service managing user permissions for exporting files to the Android Downloads folder
/// and displaying download progress in the notification bar.
class ExportPermissionService {
  static const String _prefKey = 'has_granted_storage_export_permission';

  /// Check if the user has previously granted export/storage permissions
  static Future<bool> hasGrantedPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Manually set or revoke export permission state
  static Future<void> setPermission(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, granted);
    } catch (_) {}
  }

  /// Resets permission back to unasked state
  static Future<void> resetPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  /// Verifies permission, showing an interactive permission dialog to the user if not yet granted.
  static Future<bool> ensurePermission({
    BuildContext? context,
    required String fileName,
    String fileType = 'File',
  }) async {
    // 1. If user previously granted and remembered permission, proceed immediately
    if (await hasGrantedPermission()) {
      return true;
    }

    // 2. Resolve BuildContext (either direct or via rootNavigatorKey)
    final effectiveContext = context ?? rootNavigatorKey.currentContext;
    if (effectiveContext != null && effectiveContext.mounted) {
      final granted = await showDialog<bool>(
        context: effectiveContext,
        barrierDismissible: false,
        builder: (ctx) => _ExportPermissionDialog(fileName: fileName, fileType: fileType),
      );

      if (granted == true) {
        // Trigger OS notification permission request on Android 13+ / iOS
        await PushNotificationService().requestNotificationPermission();
        return true;
      } else {
        return false;
      }
    }

    // 3. Fallback when context is not provided
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefKey) && prefs.getBool(_prefKey) == false) {
        return false;
      }
    } catch (_) {}

    await PushNotificationService().requestNotificationPermission();
    return true;
  }
}

class _ExportPermissionDialog extends StatefulWidget {
  final String fileName;
  final String fileType;

  const _ExportPermissionDialog({
    required this.fileName,
    required this.fileType,
  });

  @override
  State<_ExportPermissionDialog> createState() => _ExportPermissionDialogState();
}

class _ExportPermissionDialogState extends State<_ExportPermissionDialog> {
  bool _rememberChoice = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPine.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.downloading_rounded,
              color: AppColors.primaryPine,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Allow Storage & Download?',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Innoveity Workspace requires permission to export and save "${widget.fileName}" on your device:',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? AppColors.textLight : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),

            // Bullet 1: Downloads folder
            _buildPermissionItem(
              icon: Icons.folder_open_rounded,
              iconColor: const Color(0xFFEA580C),
              title: 'Android Downloads Folder',
              description: 'Save exported CSV and Excel spreadsheets directly into your device\'s public Downloads folder (/storage/emulated/0/Download).',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Bullet 2: Notification bar progress
            _buildPermissionItem(
              icon: Icons.notifications_active_outlined,
              iconColor: AppColors.vibrantEmerald,
              title: 'Notification Bar Progress',
              description: 'Show live progress of downloading files in your notification bar and notify you upon completion.',
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Remember choice checkbox
            InkWell(
              onTap: () => setState(() => _rememberChoice = !_rememberChoice),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberChoice,
                        activeColor: AppColors.primaryPine,
                        onChanged: (val) => setState(() => _rememberChoice = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Always allow exports to Downloads folder',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Deny',
            style: TextStyle(
              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPine,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: 0,
          ),
          onPressed: () async {
            if (_rememberChoice) {
              await ExportPermissionService.setPermission(true);
            }
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          },
          child: const Text(
            'Allow & Download',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
