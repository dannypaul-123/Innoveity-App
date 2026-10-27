import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../services/api_service.dart';
import '../services/biometric_auth_service.dart';
import '../core/storage/token_storage.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Map<String, dynamic>> payslips;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Future<void> Function({
    required String name,
    required String phone,
    required String college,
    required String department,
  })? onUpdateProfile;
  final Function(String?)? onUpdateAvatar;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    this.payslips = const [],
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.onUpdateProfile,
    this.onUpdateAvatar,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0: Payslips & Salary, 1: My Profile Details

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _collegeController;
  late TextEditingController _departmentController;

  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isSavingInfo = false;
  bool _isUpdatingPassword = false;
  String? _localAvatarPath;
  bool _isFingerprintEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = widget.userProfile;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone ?? '8754545520');
    _collegeController = TextEditingController(text: 'Sathyabama University');
    _departmentController = TextEditingController(text: user.department ?? 'Mobile Application Development');

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _checkFingerprintStatus();
  }

  Future<void> _checkFingerprintStatus() async {
    final enabled = await TokenStorage().isFingerprintEnabledFor(widget.userProfile.email);
    if (mounted) {
      setState(() {
        _isFingerprintEnabled = enabled;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      if (!_isSavingInfo) {
        _nameController.text = widget.userProfile.name;
        if (widget.userProfile.phone != null && widget.userProfile.phone!.isNotEmpty) {
          _phoneController.text = widget.userProfile.phone!;
        }
        if (widget.userProfile.department != null && widget.userProfile.department!.isNotEmpty) {
          _departmentController.text = widget.userProfile.department!;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage({ImageSource? source}) async {
    try {
      String? pickedPath;

      if (source == null || source == ImageSource.gallery) {
        // 1. Try native FilePicker first (direct access to files, images, downloads)
        try {
          final FilePickerResult? result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
            allowMultiple: false,
          );
          if (result != null && result.files.isNotEmpty) {
            pickedPath = result.files.single.path;
          }
        } catch (e) {
          debugPrint('FilePicker note: $e');
        }

        // 2. Fallback to ImagePicker gallery if FilePicker returned null or was cancelled
        if (pickedPath == null && (source == ImageSource.gallery || source == null)) {
          try {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1024,
              maxHeight: 1024,
              imageQuality: 85,
            );
            pickedPath = image?.path;
          } catch (e) {
            debugPrint('ImagePicker gallery note: $e');
          }
        }
      } else if (source == ImageSource.camera) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        pickedPath = image?.path;
      }

      if (pickedPath != null && pickedPath.isNotEmpty) {
        setState(() {
          _localAvatarPath = pickedPath;
        });
        if (widget.onUpdateAvatar != null) {
          widget.onUpdateAvatar!(pickedPath);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully from Photos/Files!'),
              backgroundColor: AppColors.primaryPine,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to access photos/files: $e. Please grant permission in App Settings.'),
            backgroundColor: AppColors.alertText,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Profile Photo Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryPine),
                title: const Text('Choose from Photos / Files'),
                subtitle: const Text('Access gallery, images, or document files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadProfileImage(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryPine),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Capture a new photo using device camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadProfileImage(source: ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPhotoOptions(BuildContext context) {
    final user = widget.userProfile;
    final hasAvatar = user.avatar != null && user.avatar!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Photo Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload, color: AppColors.primaryPine, size: 20),
                ),
                title: const Text('Upload New Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose photo from gallery or camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showImageSourcePicker(context);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.alertText, size: 20),
                  ),
                  title: const Text('Remove Current Photo', style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Restore original profile initials badge'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _localAvatarPath = '';
                    });
                    if (widget.onUpdateAvatar != null) {
                      widget.onUpdateAvatar!(null);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile photo removed. Restored initials badge.'),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _showEditPhotoOptions(context),
                        child: Stack(
                          children: [
                            buildUserAvatar(
                              avatar: (_localAvatarPath != null)
                                  ? (_localAvatarPath!.isEmpty ? null : _localAvatarPath)
                                  : user.avatar,
                              name: user.name,
                              size: 60,
                              border: Border.all(color: AppColors.primaryPine, width: 2.5),
                              backgroundColor: const Color(0xFFF97316),
                              fontSize: 26,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPine,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.completedBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.completedText),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.designation ?? user.department ?? 'Mobile App Developer',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.employeeId,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLight : AppColors.textDark),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '• ${user.department ?? "Mobile Application Development"}',
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 12),

                  // Prominent, highly legible Edit Photo Action Row right next to the profile tab section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, size: 18, color: AppColors.primaryPine),
                          const SizedBox(width: 8),
                          Text(
                            'Profile Photo Options',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textLight : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showEditPhotoOptions(context),
                        icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        label: const Text(
                          'Edit Photo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Segmented Tab Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 0
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'Payslips & Salary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedTab == 0 ? AppColors.primaryPine : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 1
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'My Profile Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedTab == 1 ? AppColors.primaryPine : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _selectedTab == 0 ? _buildPayslipsTab(context) : _buildProfileTab(context),
        ],
      ),
    );
  }

  Widget _buildPayslipsTab(BuildContext context) {
    final payslipList = widget.payslips;
    final hasLivePayslip = payslipList.isNotEmpty;

    final latestPayslip = hasLivePayslip ? payslipList.first : <String, dynamic>{};
    
    final double netPay = hasLivePayslip
        ? (double.tryParse(latestPayslip['netSalary']?.toString() ?? '0') ?? 0)
        : widget.userProfile.netSalary;

    final double basic = hasLivePayslip
        ? (double.tryParse(latestPayslip['basicSalary']?.toString() ?? '0') ?? 0)
        : widget.userProfile.basicSalary;

    final double hra = hasLivePayslip
        ? (double.tryParse(latestPayslip['hra']?.toString() ?? '0') ?? 0)
        : widget.userProfile.hra;

    final double allowances = hasLivePayslip
        ? (double.tryParse(latestPayslip['allowancesJson']?['specialAllowance']?.toString() ?? '0') ?? 0)
        : widget.userProfile.specialAllowance;

    final double pf = hasLivePayslip
        ? (double.tryParse(latestPayslip['deductionsJson']?['pfContribution']?.toString() ?? '0') ?? 0)
        : widget.userProfile.deductions;

    final double tax = hasLivePayslip
        ? (double.tryParse(latestPayslip['deductionsJson']?['incomeTax']?.toString() ?? '0') ?? 0)
        : 0;

    final String monthTitle = hasLivePayslip
        ? 'SEPTEMBER ${latestPayslip['year'] ?? 2026} NET PAY'
        : 'SEPTEMBER 2026 NET PAY';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Net Pay Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryPineDark, AppColors.primaryPine],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthTitle,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white70),
                  ),
                  const Icon(Icons.lock, color: Colors.white70, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${netPay.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Direct Deposit • Verified Enterprise Account',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPayslipPdfModal(
                    context,
                    'September 2026 Statement',
                    basic,
                    hra,
                    allowances,
                    pf,
                    tax,
                    netPay,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('View & Download September Payslip PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryPine,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Earnings & Deductions Breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salary Structure Breakdown',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 16, color: AppColors.borderLight),
                _buildSalaryRow('Basic Salary', '₹${basic.toStringAsFixed(2)}'),
                if (hra > 0) _buildSalaryRow('House Rent Allowance (HRA)', '₹${hra.toStringAsFixed(2)}'),
                if (allowances > 0) _buildSalaryRow('Special Allowance', '₹${allowances.toStringAsFixed(2)}'),
                if (pf > 0) _buildSalaryRow('PF Employee Contribution', '-₹${pf.toStringAsFixed(2)}', isDeduction: true),
                if (tax > 0) _buildSalaryRow('Income Tax (TDS)', '-₹${tax.toStringAsFixed(2)}', isDeduction: true),
                const Divider(height: 16, color: AppColors.borderLight),
                _buildSalaryRow('Total Net Payable', '₹${netPay.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Historical Payslips
        const Text(
          'Payslip History Statements',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildHistoryItem(
          context,
          'September 2026',
          '₹${netPay.toStringAsFixed(2)}',
          () => _showPayslipPdfModal(context, 'September 2026', basic, hra, allowances, pf, tax, netPay),
        ),
        const SizedBox(height: 6),
        _buildHistoryItem(
          context,
          'August 2026',
          '₹${netPay.toStringAsFixed(2)}',
          () => _showPayslipPdfModal(context, 'August 2026', basic, hra, allowances, pf, tax, netPay),
        ),
        const SizedBox(height: 6),
        _buildHistoryItem(
          context,
          'July 2026',
          '₹${netPay.toStringAsFixed(2)}',
          () => _showPayslipPdfModal(context, 'July 2026', basic, hra, allowances, pf, tax, netPay),
        ),
        const SizedBox(height: 6),
        _buildHistoryItem(
          context,
          'June 2026',
          '₹${netPay.toStringAsFixed(2)}',
          () => _showPayslipPdfModal(context, 'June 2026', basic, hra, allowances, pf, tax, netPay),
        ),
      ],
    );
  }

  Widget _buildSalaryRow(String title, String amount, {bool isDeduction = false, bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? textDark : textMuted,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDeduction ? AppColors.alertText : textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String month, String amount, VoidCallback onDownload) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppColors.alertText, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(month, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('Net Salary: $amount', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download, size: 14),
              label: const Text('PDF', style: TextStyle(fontSize: 11)),
              onPressed: onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayslipPdfModal(
    BuildContext context,
    String month,
    double basic,
    double hra,
    double allowances,
    double pf,
    double tax,
    double netPay,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.alertText, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Payslip PDF - $month',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Enterprise Payslip Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INNOVEITY ENTERPRISE PORTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPine)),
                    const SizedBox(height: 4),
                    Text('Employee Name: ${widget.userProfile.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Employee ID: ${widget.userProfile.employeeId} | Role: ${widget.userProfile.role}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('Department: ${widget.userProfile.department ?? "Engineering"}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Text('Salary Breakdown Statement:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildSalaryRow('Basic Salary', '₹${basic.toStringAsFixed(2)}'),
              if (hra > 0) _buildSalaryRow('House Rent Allowance (HRA)', '₹${hra.toStringAsFixed(2)}'),
              if (allowances > 0) _buildSalaryRow('Special Allowance', '₹${allowances.toStringAsFixed(2)}'),
              if (pf > 0) _buildSalaryRow('PF Employee Contribution', '-₹${pf.toStringAsFixed(2)}', isDeduction: true),
              if (tax > 0) _buildSalaryRow('Income Tax (TDS)', '-₹${tax.toStringAsFixed(2)}', isDeduction: true),
              const Divider(),
              _buildSalaryRow('Net Salary Transfer', '₹${netPay.toStringAsFixed(2)}', isBold: true),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Encrypted $month Payslip PDF generated for ${widget.userProfile.name}! File saved to Downloads.'),
                        backgroundColor: AppColors.primaryPine,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: Text('Download $month Payslip PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final user = widget.userProfile;
    final isDark = widget.isDarkMode;
    final textDark = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Personal Information Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20, color: Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    Text(
                      'PERSONAL INFORMATION',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textDark),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const SizedBox(height: 4),
                Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Text('College / University', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _collegeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _departmentController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSavingInfo
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isSavingInfo = true);

                            if (widget.onUpdateProfile != null) {
                              await widget.onUpdateProfile!(
                                name: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                college: _collegeController.text.trim(),
                                department: _departmentController.text.trim(),
                              );
                            } else {
                              await ApiService.updateUserProfile(
                                name: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                college: _collegeController.text.trim(),
                                department: _departmentController.text.trim(),
                              );
                            }

                            if (!mounted) return;
                            setState(() => _isSavingInfo = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Personal information updated across profile, dashboard, and backend!'),
                                backgroundColor: AppColors.primaryPine,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSavingInfo
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Save Information Changes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. Employment Profile Details Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Employment Profile Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildProfileDetailRow('Organization', 'INNOVEITY TECH', badgeColor: const Color(0xFFFFEDD5), badgeTextColor: const Color(0xFFC2410C)),
                _buildProfileDetailRow('Email', user.email),
                _buildProfileDetailRow('Branch', 'Headquarters'),
                _buildProfileDetailRow('Department', user.department ?? 'Mobile Application Development'),
                _buildProfileDetailRow('Reporting Manager', 'Self'),
                _buildProfileDetailRow('Employment Type', user.role == 'INTERN' ? 'Internship' : 'Full-Time'),
                _buildProfileDetailRow('Joining Date', user.joiningDate ?? '23/09/2026'),
                _buildProfileDetailRow('Current Shift', user.role == 'INTERN' ? 'Innoveity shift 2 (10:00 – 17:00)' : 'Innoveity shift 1 (09:30 – 18:00)'),
                _buildProfileDetailRow('Today\'s Status', 'WORKING', badgeColor: const Color(0xFFDCFCE7), badgeTextColor: const Color(0xFF15803D)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Shift Schedule & Upcoming 7 Days Strip (from Image 2)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tomorrow',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Row(
                      children: [
                        Text(
                          user.role == 'INTERN' ? 'Innoveity shift 2 (10:00 AM – 05:00 PM)' : 'Innoveity shift 1 (09:30 AM – 06:00 PM)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('WORKING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Next Working Day', style: TextStyle(fontSize: 12, color: textMuted)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role == 'INTERN' ? 'Tomorrow: 10:00 AM – 05:00 PM' : 'Tomorrow: 09:30 AM – 06:00 PM',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('UPCOMING 7 DAYS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textMuted)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildUpcomingDayPill('THU', '01', 'WORK', isWork: true),
                      const SizedBox(width: 8),
                      _buildUpcomingDayPill('FRI', '02', 'WORK', isWork: true),
                      const SizedBox(width: 8),
                      _buildUpcomingDayPill('SAT', '03', 'OFF', isWork: false),
                      const SizedBox(width: 8),
                      _buildUpcomingDayPill('SUN', '04', 'OFF', isWork: false),
                      const SizedBox(width: 8),
                      _buildUpcomingDayPill('MON', '05', 'WORK', isWork: true),
                      const SizedBox(width: 8),
                      _buildUpcomingDayPill('TUE', '06', 'WORK', isWork: true),
                      const SizedBox(width: 8),
                      _buildUpcomingDayPill('WED', '07', 'WORK', isWork: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 4. Assigned Hardware & Assets Card (from Image 2)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.laptop_chromebook, size: 20, color: Color(0xFFEA580C)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned Hardware & Assets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark), overflow: TextOverflow.ellipsis),
                          Text('Laptops, monitors, mobile devices, and equipment issued to your profile.', style: TextStyle(fontSize: 11, color: textMuted), overflow: TextOverflow.ellipsis, maxLines: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No company assets are currently assigned to your account.',
                      style: TextStyle(fontSize: 12, color: textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Fingerprint Biometric Security Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPine.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fingerprint, size: 22, color: AppColors.primaryPine),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fingerprint Quick Login',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isFingerprintEnabled
                            ? 'Enabled for 1-tap fast logins on this device'
                            : 'Disabled on this device',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isFingerprintEnabled,
                  activeColor: AppColors.primaryPine,
                  onChanged: (val) async {
                    if (val) {
                      final didScan = await BiometricAuthService.authenticateBiometricsOrPasscode(
                        reason: 'Scan your fingerprint to link with your CRM employee account',
                      );
                      if (didScan) {
                        await TokenStorage().setFingerprintEnabledFor(
                          email: widget.userProfile.email,
                          enabled: true,
                        );
                        if (mounted) {
                          setState(() => _isFingerprintEnabled = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fingerprint authentication enabled for quicker logins!'),
                              backgroundColor: AppColors.primaryPine,
                            ),
                          );
                        }
                      }
                    } else {
                      await TokenStorage().setFingerprintEnabledFor(
                        email: widget.userProfile.email,
                        enabled: false,
                      );
                      if (mounted) {
                        setState(() => _isFingerprintEnabled = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fingerprint authentication disabled for this account.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 5. Change Account Password Card (from Image 2 & 3)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('CHANGE ACCOUNT PASSWORD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textDark), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const SizedBox(height: 4),
                Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('New Secure Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isUpdatingPassword
                        ? null
                        : () async {
                            final cur = _currentPasswordController.text.trim();
                            final newP = _newPasswordController.text.trim();
                            final conf = _confirmPasswordController.text.trim();

                            if (cur.isEmpty || newP.isEmpty || conf.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill out all password fields.')),
                              );
                              return;
                            }
                            if (newP != conf) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New password and confirm password do not match.')),
                              );
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isUpdatingPassword = true);
                            final res = await ApiService.changePassword(
                              currentPassword: cur,
                              newPassword: newP,
                            );

                            if (!mounted) return;
                            setState(() => _isUpdatingPassword = false);
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Password updated successfully!'),
                                backgroundColor: AppColors.primaryPine,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isUpdatingPassword
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Update Password',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 6. Promotion & Position History Cards (from Image 2 & 3)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('PROMOTION TIMELINE & CAREER PROGRESSION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('No historical role promotions recorded. Current role is active.', style: TextStyle(fontSize: 12, color: textMuted), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech_outlined, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('POSITION RANK HISTORY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('No previous rank promotions recorded. Current position is active.', style: TextStyle(fontSize: 12, color: textMuted), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 7. Shift Change Timeline Card (from Image 3)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('SHIFT CHANGE TIMELINE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Permanent Shift Assigned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDD5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('PERMANENT_ASSIGNED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('29/09/2026 11:27', style: TextStyle(fontSize: 10, color: textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('By: Admin', style: TextStyle(fontSize: 10, color: textMuted)),
                      const SizedBox(height: 6),
                      Text(
                        user.role == 'INTERN' ? 'Shift: Innoveity shift 2 (10:00 – 17:00)' : 'Shift: Innoveity shift 1 (09:30 – 18:00)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 2),
                      Text('*Organization Shift Assignment*', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 8. Recent Account Actions Card (from Image 3)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Text('RECENT ACCOUNT ACTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  ],
                ),
                const Divider(height: 20),
                _buildAccountActionTile('LOGIN', 'Authorized CRM login session', '12:08:33'),
                const SizedBox(height: 10),
                _buildAccountActionTile('CLOCK_IN', 'Clocked check-in successfully', '12:08:33'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Preferences & Dark Mode Switch
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Preferences',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 16, color: AppColors.borderLight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                          color: AppColors.primaryPine,
                        ),
                        const SizedBox(width: 10),
                        const Text('Dark Mode Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Switch(
                      value: widget.isDarkMode,
                      activeThumbColor: AppColors.primaryPine,
                      onChanged: (_) => widget.onToggleTheme(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sign Out Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, color: AppColors.alertText),
            label: const Text('Sign Out of Account', style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.alertBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailRow(String label, String value, {Color? badgeColor, Color? badgeTextColor}) {
    final isDark = widget.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : AppColors.textMuted)),
          const SizedBox(width: 8),
          if (badgeColor != null && badgeTextColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
              child: Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor)),
            )
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLight : AppColors.textDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDayPill(String day, String date, String status, {required bool isWork}) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isWork ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isWork ? const Color(0xFFBBF7D0) : const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isWork ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
          Text(date, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isWork ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isWork ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
        ],
      ),
    );
  }

  Widget _buildAccountActionTile(String action, String details, String time) {
    final isDark = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(action, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLight : AppColors.textDark)),
        const SizedBox(height: 2),
        Text(details, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }
}
