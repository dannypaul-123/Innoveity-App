import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';

class CandidateTypeOption {
  final String id;
  final String title;
  final String desc;
  final IconData icon;

  const CandidateTypeOption({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
  });
}

class UserOnboardingWizardModal extends StatefulWidget {
  final String targetRole; // 'INTERN' or 'EMPLOYEE'
  final Function(UserProfile newProfile, String candidateType) onComplete;

  const UserOnboardingWizardModal({
    super.key,
    required this.targetRole,
    required this.onComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetRole,
    required Function(UserProfile newProfile, String candidateType) onComplete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserOnboardingWizardModal(
        targetRole: targetRole,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<UserOnboardingWizardModal> createState() => _UserOnboardingWizardModalState();
}

class _UserOnboardingWizardModalState extends State<UserOnboardingWizardModal> {
  int _currentStep = 1; // 1: Candidate Type, 2: Personal Details, 3: Organization

  // Role Choice State (Intern vs Employee)
  late String _selectedRole;

  // Step 1: Candidate Type State
  String _selectedCandidateType = 'Student';
  static const List<CandidateTypeOption> _candidateTypes = [
    CandidateTypeOption(
      id: 'Student',
      title: 'Student',
      desc: 'Currently enrolled in college / university',
      icon: Icons.school_rounded,
    ),
    CandidateTypeOption(
      id: 'Graduated',
      title: 'Graduated',
      desc: 'Completed degree, holds final marks / CGPA',
      icon: Icons.workspace_premium_rounded,
    ),
    CandidateTypeOption(
      id: 'Fresher',
      title: 'Fresher',
      desc: 'Recent graduate, entry-level candidate',
      icon: Icons.badge_rounded,
    ),
    CandidateTypeOption(
      id: 'Professional',
      title: 'Professional',
      desc: 'Prior industry employment experience',
      icon: Icons.business_center_rounded,
    ),
  ];

  // Step 2: Personal Details Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime _dob = DateTime(2002, 6, 15);
  String _gender = 'Male';

  // Dynamic Candidate Fields
  final _collegeCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _gradYearCtrl = TextEditingController(text: '2026');
  final _currentSemCtrl = TextEditingController(text: '3rd Year / 6th Sem');
  final _cgpaCtrl = TextEditingController();
  final _prevCompanyCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  // Resume Attachment State
  String? _attachedFileName;
  int? _attachedFileSizeKb;
  bool _hasGrantedFileAccess = false;

  // Step 3: Organization Controllers
  String _department = 'Software Engineering';
  final _designationCtrl = TextEditingController();
  DateTime _joiningDate = DateTime(2026, 10, 15);
  final _salaryCtrl = TextEditingController();
  String _reportingManager = 'System Admin';
  String _workMode = 'In-Office';

  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.targetRole.toUpperCase() == 'INTERN' ? 'INTERN' : 'EMPLOYEE';
    final isIntern = _selectedRole == 'INTERN';
    _designationCtrl.text = isIntern ? 'Software Engineering Intern' : 'Software Engineer';
    _salaryCtrl.text = isIntern ? '12000' : '35000';
  }

  void _updateRole(String role) {
    setState(() {
      _selectedRole = role;
      final isIntern = role == 'INTERN';
      if (_designationCtrl.text.isEmpty ||
          _designationCtrl.text == 'Software Engineering Intern' ||
          _designationCtrl.text == 'Software Engineer') {
        _designationCtrl.text = isIntern ? 'Software Engineering Intern' : 'Software Engineer';
      }
      if (_salaryCtrl.text.isEmpty || _salaryCtrl.text == '12000' || _salaryCtrl.text == '35000') {
        _salaryCtrl.text = isIntern ? '12000' : '35000';
      }
      if (isIntern && _selectedCandidateType == 'Professional') {
        _selectedCandidateType = 'Student';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _collegeCtrl.dispose();
    _degreeCtrl.dispose();
    _gradYearCtrl.dispose();
    _currentSemCtrl.dispose();
    _cgpaCtrl.dispose();
    _prevCompanyCtrl.dispose();
    _experienceCtrl.dispose();
    _skillsCtrl.dispose();
    _designationCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1975, 1, 1),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFEA580C),
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2028, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFEA580C),
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _joiningDate = picked);
  }

  Future<bool> _requestFileAccessPermission() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_shared_rounded,
                  color: Color(0xFFEA580C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Allow Access to Files?',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Innoveity Portal requires permission to access your device\'s files and documents to browse and attach the candidate\'s Resume / CV (PDF, DOCX).',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, size: 18, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Read-only access is used strictly to attach the selected document.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Don\'t Allow',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
              label: const Text(
                'Allow Access',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        );
      },
    );

    return granted ?? false;
  }

  Future<void> _pickResumeFile() async {
    // 1. Ask user for file access permission if not already granted
    if (!_hasGrantedFileAccess) {
      final allowed = await _requestFileAccessPermission();
      if (!allowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File access permission was not granted.'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      _hasGrantedFileAccess = true;
    }

    // 2. Open File Explorer / Picker
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
        dialogTitle: 'Select Candidate Resume / CV',
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final fileSizeKb = pickedFile.size > 0
            ? (pickedFile.size / 1024).round()
            : 380;

        setState(() {
          _attachedFileName = pickedFile.name;
          _attachedFileSizeKb = fileSizeKb;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Attached: ${pickedFile.name} ($fileSizeKb KB)'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // User closed the file explorer without picking
        if (mounted && _attachedFileName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected from file explorer.'),
              backgroundColor: Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file explorer: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleComplete() {
    if (!_formKeyStep3.currentState!.validate()) return;

    final isIntern = _selectedRole == 'INTERN';
    final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final empId = isIntern ? 'IN-$randomSuffix' : 'EM-$randomSuffix';
    final salaryVal = double.tryParse(_salaryCtrl.text.trim()) ?? (isIntern ? 12000.0 : 35000.0);

    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final joinStr = '${months[_joiningDate.month - 1]} ${_joiningDate.day}, ${_joiningDate.year}';

    final newProfile = UserProfile(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      employeeId: empId,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      role: _selectedRole,
      department: _department,
      designation: _designationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? '+91 98401 23456' : _phoneCtrl.text.trim(),
      joiningDate: joinStr,
      basicSalary: salaryVal * 0.7,
      hra: salaryVal * 0.3,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: salaryVal,
      candidateType: _selectedCandidateType,
      dob: _formatDate(_dob),
      gender: _gender,
      college: _collegeCtrl.text.trim(),
      degree: _degreeCtrl.text.trim(),
      gradYear: _gradYearCtrl.text.trim(),
      currentSem: _currentSemCtrl.text.trim(),
      cgpa: _cgpaCtrl.text.trim(),
      prevCompany: _prevCompanyCtrl.text.trim(),
      experience: _experienceCtrl.text.trim(),
      skills: _skillsCtrl.text.trim(),
      reportingManager: _reportingManager,
      workMode: _workMode,
      resumeFileName: _attachedFileName,
    );

    widget.onComplete(newProfile, _selectedCandidateType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIntern = _selectedRole == 'INTERN';
    final roleTitle = isIntern ? 'Intern' : 'Employee';

    return Dialog(
      backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header matching Screenshot 1 & 2
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      isIntern ? Icons.school_rounded : Icons.person_add_alt_1_rounded,
                      color: const Color(0xFFEA580C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Onboard New $roleTitle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '3-Step Dynamic Onboarding Wizard',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),

            // Stepper Tabs matching Screenshot 1, 2, 3
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStepTab(
                      stepNumber: 1,
                      label: 'Candidate Type',
                      isActive: _currentStep == 1,
                      isCompleted: _currentStep > 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStepTab(
                      stepNumber: 2,
                      label: 'Personal Details',
                      isActive: _currentStep == 2,
                      isCompleted: _currentStep > 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStepTab(
                      stepNumber: 3,
                      label: 'Organization',
                      isActive: _currentStep == 3,
                      isCompleted: false,
                    ),
                  ),
                ],
              ),
            ),

            // Step Content Body (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: _buildCurrentStepBody(isDark),
              ),
            ),

            const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),

            // Footer Navigation Buttons matching Screenshot 1, 2, 3
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (_currentStep == 1) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _currentStep--);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      _currentStep == 1 ? 'Cancel' : 'Back',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep == 1) {
                        setState(() => _currentStep = 2);
                      } else if (_currentStep == 2) {
                        if (_formKeyStep2.currentState!.validate()) {
                          setState(() => _currentStep = 3);
                        }
                      } else {
                        _handleComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentStep == 3
                              ? 'Complete Onboarding'
                              : 'Next Step',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_currentStep < 3) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFEA580C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (primaryOrange.withValues(alpha: isDark ? 0.2 : 0.08))
            : (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? primaryOrange
              : (isCompleted
                  ? const Color(0xFF10B981)
                  : (isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0))),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'STEP $stepNumber',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isActive
                      ? primaryOrange
                      : (isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8)),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive
                    ? primaryOrange
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepBody(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1CandidateType(isDark);
      case 2:
        return _buildStep2PersonalDetails(isDark);
      case 3:
        return _buildStep3Organization(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoleSelectionCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    const primaryOrange = Color(0xFFEA580C);
    return InkWell(
      onTap: () => _updateRole(role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? (primaryOrange.withValues(alpha: isDark ? 0.2 : 0.08))
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryOrange
                : (isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryOrange.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryOrange.withValues(alpha: 0.15)
                    : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryOrange : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? primaryOrange
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? primaryOrange : const Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Candidate Type Selection matching Screenshot 1 & 2
  Widget _buildStep1CandidateType(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          'ONBOARDING ROLE *',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose whether to onboard this candidate as an Intern or regular Employee.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        // Role Choice Cards: Intern vs Employee
        Row(
          children: [
            Expanded(
              child: _buildRoleSelectionCard(
                role: 'INTERN',
                title: 'Intern',
                subtitle: 'Contract & Stipend',
                icon: Icons.school_rounded,
                isSelected: _selectedRole == 'INTERN',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleSelectionCard(
                role: 'EMPLOYEE',
                title: 'Employee',
                subtitle: 'Full-time & Payroll',
                icon: Icons.badge_rounded,
                isSelected: _selectedRole == 'EMPLOYEE',
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 14),

        Text(
          'SELECT CANDIDATE TYPE *',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the candidate category. Exactly one option must be selected.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // 4 Candidate Type Radio Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 480;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 2 : 1,
                mainAxisExtent: 82,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _candidateTypes.length,
              itemBuilder: (context, idx) {
                final type = _candidateTypes[idx];
                final isSelected = _selectedCandidateType == type.id;
                const primaryOrange = Color(0xFFEA580C);

                return InkWell(
                  onTap: () => setState(() => _selectedCandidateType = type.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (primaryOrange.withValues(alpha: isDark ? 0.15 : 0.05))
                          : (isDark ? AppColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryOrange
                            : (isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: primaryOrange.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                type.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? primaryOrange
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                type.desc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? primaryOrange : const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDobField(bool isDark) {
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth *',
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFFEA580C)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        child: Text(
          _formatDate(_dob),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(fontSize: 13))),
      ],
      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
    );
  }

  Widget _buildJoiningDateField(bool isDark) {
    return InkWell(
      onTap: _pickJoiningDate,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Joining Date *',
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFFEA580C)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        child: Text(
          _formatDate(_joiningDate),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  // STEP 2: Personal Details matching Screenshot 3
  Widget _buildStep2PersonalDetails(bool isDark) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final nameField = _buildTextField(
                controller: _nameCtrl,
                label: 'Full Name *',
                hint: 'John Doe',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              );
              final emailField = _buildTextField(
                controller: _emailCtrl,
                label: 'Email Address *',
                hint: 'john@innoveity.com',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Invalid email address';
                  return null;
                },
              );

              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    nameField,
                    const SizedBox(height: 14),
                    emailField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 14),
                  Expanded(child: emailField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final phoneField = _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone Number *',
                hint: '9876543210',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
              );
              final dobField = _buildDobField(isDark);
              final genderField = _buildGenderField();

              if (constraints.maxWidth < 460) {
                return Column(
                  children: [
                    phoneField,
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: dobField),
                        const SizedBox(width: 14),
                        Expanded(child: genderField),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: phoneField),
                  const SizedBox(width: 14),
                  Expanded(child: dobField),
                  const SizedBox(width: 14),
                  Expanded(child: genderField),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // Dynamic Sub-section based on Candidate Type (e.g. Student Requirements)
          _buildCandidateSpecificFields(isDark),

          const SizedBox(height: 16),

          // Resume / CV Attachment Container matching Screenshot 3
          Text(
            'Resume / CV Attachment (Optional)',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickResumeFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _attachedFileName != null
                      ? const Color(0xFF10B981)
                      : (isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                  style: BorderStyle.solid,
                  width: 1.2,
                ),
              ),
              child: _attachedFileName != null
                  ? Row(
                      children: [
                        Icon(
                          _attachedFileName!.toLowerCase().endsWith('.doc') ||
                                  _attachedFileName!.toLowerCase().endsWith('.docx')
                              ? Icons.description_rounded
                              : Icons.picture_as_pdf_rounded,
                          color: const Color(0xFF10B981),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attachedFileName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$_attachedFileSizeKb KB • Document Verified (Tap to change)',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove Attachment',
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => setState(() {
                            _attachedFileName = null;
                            _attachedFileSizeKb = null;
                          }),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload_outlined, color: Color(0xFFEA580C), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Click to attach or drop candidate Resume / CV (PDF, DOCX)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic Requirements fields matching Screenshot 3
  Widget _buildCandidateSpecificFields(bool isDark) {
    if (_selectedCandidateType == 'Student') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.school_outlined, size: 16, color: Color(0xFFEA580C)),
              SizedBox(width: 6),
              Text(
                'Student Requirements',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final collegeField = _buildTextField(
                controller: _collegeCtrl,
                label: 'College / Institution *',
                hint: 'e.g. MIT / IIT / Anna University',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'College required' : null,
              );
              final degreeField = _buildTextField(
                controller: _degreeCtrl,
                label: 'Degree / Stream *',
                hint: 'e.g. B.Tech Computer Science / MCA',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Degree required' : null,
              );
              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    collegeField,
                    const SizedBox(height: 12),
                    degreeField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: collegeField),
                  const SizedBox(width: 14),
                  Expanded(child: degreeField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final gradYearField = _buildTextField(
                controller: _gradYearCtrl,
                label: 'Graduation Year *',
                hint: 'e.g. 2026',
                keyboardType: TextInputType.number,
              );
              final semField = _buildTextField(
                controller: _currentSemCtrl,
                label: 'Current Semester / Year *',
                hint: 'e.g. 3rd Year / 6th Sem',
              );
              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    gradYearField,
                    const SizedBox(height: 12),
                    semField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: gradYearField),
                  const SizedBox(width: 14),
                  Expanded(child: semField),
                ],
              );
            },
          ),
        ],
      );
    } else if (_selectedCandidateType == 'Graduated') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Graduate Academic Background',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final instField = _buildTextField(
                controller: _collegeCtrl,
                label: 'Graduated Institution *',
                hint: 'e.g. University of Madras',
              );
              final degreeField = _buildTextField(
                controller: _degreeCtrl,
                label: 'Degree / Major *',
                hint: 'e.g. B.Sc Computer Science',
              );
              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    instField,
                    const SizedBox(height: 12),
                    degreeField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: instField),
                  const SizedBox(width: 14),
                  Expanded(child: degreeField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cgpaField = _buildTextField(
                controller: _cgpaCtrl,
                label: 'Final CGPA / Marks *',
                hint: 'e.g. 8.4 CGPA / 82%',
              );
              final yearField = _buildTextField(
                controller: _gradYearCtrl,
                label: 'Completion Year *',
                hint: 'e.g. 2024',
              );
              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    cgpaField,
                    const SizedBox(height: 12),
                    yearField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cgpaField),
                  const SizedBox(width: 14),
                  Expanded(child: yearField),
                ],
              );
            },
          ),
        ],
      );
    } else if (_selectedCandidateType == 'Fresher') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fresher Profile & Skills',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final qualField = _buildTextField(
                controller: _degreeCtrl,
                label: 'Highest Qualification *',
                hint: 'e.g. B.Tech / BCA / MCA',
              );
              final skillsField = _buildTextField(
                controller: _skillsCtrl,
                label: 'Key Skills *',
                hint: 'e.g. Dart, Flutter, Python, SQL',
              );
              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    qualField,
                    const SizedBox(height: 12),
                    skillsField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: qualField),
                  const SizedBox(width: 14),
                  Expanded(child: skillsField),
                ],
              );
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prior Industry Experience',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compField = _buildTextField(
                controller: _prevCompanyCtrl,
                label: 'Previous Employer *',
                hint: 'e.g. TechCorp Solutions Ltd',
              );
              final expField = _buildTextField(
                controller: _experienceCtrl,
                label: 'Total Experience *',
                hint: 'e.g. 2.5 Years',
              );
              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    compField,
                    const SizedBox(height: 12),
                    expField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: compField),
                  const SizedBox(width: 14),
                  Expanded(child: expField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _skillsCtrl,
            label: 'Core Competencies / Tech Stack *',
            hint: 'e.g. Mobile Architecture, Spring Boot, React, AWS',
          ),
        ],
      );
    }
  }

  // STEP 3: Organization Details
  Widget _buildStep3Organization(bool isDark) {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final deptField = DropdownButtonFormField<String>(
                initialValue: _department,
                decoration: InputDecoration(
                  labelText: 'Department *',
                  labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'Software Engineering', child: Text('Software Engineering')),
                  DropdownMenuItem(value: 'Mobile App Development', child: Text('Mobile App Development')),
                  DropdownMenuItem(value: 'Quality Assurance', child: Text('Quality Assurance')),
                  DropdownMenuItem(value: 'UI/UX Design', child: Text('UI/UX Design')),
                  DropdownMenuItem(value: 'MCA Department', child: Text('MCA Department')),
                  DropdownMenuItem(value: 'Management', child: Text('Management')),
                ],
                onChanged: (v) => setState(() => _department = v ?? 'Software Engineering'),
              );
              final desigField = _buildTextField(
                controller: _designationCtrl,
                label: 'Designation / Role Title *',
                hint: 'e.g. Software Specialist',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
              );

              if (constraints.maxWidth < 480) {
                return Column(
                  children: [
                    deptField,
                    const SizedBox(height: 14),
                    desigField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: deptField),
                  const SizedBox(width: 14),
                  Expanded(child: desigField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final joinDateField = _buildJoiningDateField(isDark);
              final salaryField = _buildTextField(
                controller: _salaryCtrl,
                label: _selectedRole == 'INTERN' ? 'Monthly Stipend (₹) *' : 'Monthly Gross Salary (₹) *',
                hint: _selectedRole == 'INTERN' ? 'e.g. 15000' : 'e.g. 35000',
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
              );

              if (constraints.maxWidth < 450) {
                return Column(
                  children: [
                    joinDateField,
                    const SizedBox(height: 14),
                    salaryField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: joinDateField),
                  const SizedBox(width: 14),
                  Expanded(child: salaryField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final managerField = DropdownButtonFormField<String>(
                initialValue: _reportingManager,
                decoration: InputDecoration(
                  labelText: 'Reporting Manager / Mentor',
                  labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'System Admin', child: Text('System Admin (Director)')),
                  DropdownMenuItem(value: 'Paul Renine', child: Text('Paul Renine (Lead Backend)')),
                  DropdownMenuItem(value: 'Suraj S', child: Text('Suraj S (Lead Systems)')),
                  DropdownMenuItem(value: 'Daniel Paul', child: Text('Daniel Paul (Senior Full Stack)')),
                  DropdownMenuItem(value: 'Anto A', child: Text('Anto A (Mobile Lead)')),
                ],
                onChanged: (v) => setState(() => _reportingManager = v ?? 'System Admin'),
              );
              final workModeField = DropdownButtonFormField<String>(
                initialValue: ['In-Office', 'Work From Home (WFH)', 'Hybrid'].contains(_workMode)
                    ? _workMode
                    : (_workMode.toUpperCase().contains('WFH') || _workMode.toUpperCase().contains('HOME')
                        ? 'Work From Home (WFH)'
                        : 'In-Office'),
                decoration: InputDecoration(
                  labelText: 'Work Mode',
                  labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'In-Office', child: Text('In-Office (HQ Verified)')),
                  DropdownMenuItem(value: 'Work From Home (WFH)', child: Text('Work From Home (WFH)')),
                  DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid (3 Days HQ)')),
                ],
                onChanged: (v) => setState(() => _workMode = v ?? 'In-Office'),
              );

              if (constraints.maxWidth < 480) {
                return Column(
                  children: [
                    managerField,
                    const SizedBox(height: 14),
                    workModeField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: managerField),
                  const SizedBox(width: 14),
                  Expanded(child: workModeField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    );
  }
}
