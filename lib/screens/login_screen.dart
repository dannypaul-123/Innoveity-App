import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';
import '../theme/app_colors.dart';
import '../core/storage/token_storage.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final Future<bool> Function(String email, String password)? onLoginWithCredentials;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onLoginWithCredentials,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _authModeIndex = 0; // 0: Work Email, 1: PIN / Passcode
  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _savePassword = true;
  String _enteredPin = "";
  List<SavedAccountCredential> _savedAccounts = [];
  String? _enrolledFingerprintEmail;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _loadSavedUserLogin();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedUserLogin() async {
    try {
      final accounts = await TokenStorage().readSavedAccounts();
      final savedEmail = await TokenStorage().readSavedUserLogin();
      final enrolledFingerprint = await TokenStorage().getFingerprintEnrolledEmail();
      if (mounted) {
        setState(() {
          _savedAccounts = accounts;
          _enrolledFingerprintEmail = enrolledFingerprint;
          if (accounts.isNotEmpty) {
            // Find last used account or first saved account
            final matched = accounts.firstWhere(
              (a) => a.email.toLowerCase() == (savedEmail ?? '').toLowerCase(),
              orElse: () => accounts.first,
            );
            if (_emailController.text.isEmpty) {
              _emailController.text = matched.email;
              _passwordController.text = matched.password;
            } else if (_passwordController.text.isEmpty &&
                _emailController.text.trim().toLowerCase() == matched.email.toLowerCase()) {
              _passwordController.text = matched.password;
            }
          } else if (savedEmail != null && savedEmail.isNotEmpty && _emailController.text.isEmpty) {
            _emailController.text = savedEmail;
          }
        });
      }
    } catch (_) {}
  }

  void _selectSavedAccount(SavedAccountCredential account) {
    setState(() {
      _emailController.text = account.email;
      _passwordController.text = account.password;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded credentials for ${account.email}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteSavedAccount(String email) async {
    await TokenStorage().deleteSavedAccount(email);
    final accounts = await TokenStorage().readSavedAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
        if (_emailController.text.trim().toLowerCase() == email.trim().toLowerCase()) {
          _emailController.clear();
          _passwordController.clear();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed saved credentials for "$email"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveCurrentCredentialsManually() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email/address and password to save.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await TokenStorage().saveAccountCredential(email: email, password: password);
    final accounts = await TokenStorage().readSavedAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved password for "$email"!'),
          backgroundColor: AppColors.primaryPine,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleBiometricOrPasscodeAuth() async {
    // 1. Get enrolled fingerprint email
    final enrolledEmail = await TokenStorage().getFingerprintEnrolledEmail();

    if (enrolledEmail == null || enrolledEmail.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                ),
                const SizedBox(width: 10),
                Text(
                  'Fingerprint Not Configured',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
              ],
            ),
            content: Text(
              'Newer users must first log in and validate their credentials with the CRM backend before setting up fingerprint for quicker logins.',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Validate that the employee account is registered in the CRM backend!
    final isAddedToCrm = AppState.isEmployeeInCrmBackend(enrolledEmail);
    if (!isAddedToCrm) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            content: Text(
              'Only employees whose accounts are added to the CRM backend can access fingerprint authentication.\n\nAccount "$enrolledEmail" is not recognized in the CRM backend. Please contact your system administrator.',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 3. Authenticate with fingerprint/biometrics
    final success = await BiometricAuthService.authenticateBiometricsOrPasscode(
      reason: 'Scan Fingerprint to log in to Innoveity CRM as $enrolledEmail',
    );

    if (success && mounted) {
      final accounts = await TokenStorage().readSavedAccounts();
      final matchedAccount = accounts.firstWhere(
        (a) => a.email.trim().toLowerCase() == enrolledEmail.trim().toLowerCase(),
        orElse: () => SavedAccountCredential(
          email: enrolledEmail,
          password: 'password',
          savedAt: DateTime.now(),
        ),
      );

      _emailController.text = matchedAccount.email;
      _passwordController.text = matchedAccount.password;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fingerprint verified for ${matchedAccount.email}'),
          backgroundColor: AppColors.primaryPine,
          duration: const Duration(seconds: 1),
        ),
      );

      if (widget.onLoginWithCredentials != null) {
        final loginOk = await widget.onLoginWithCredentials!(
          matchedAccount.email,
          matchedAccount.password,
        );
        if (loginOk) {
          widget.onLoginSuccess();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CRM credential verification failed. Please log in with password.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        widget.onLoginSuccess();
      }
    }
  }

  Future<void> _promptFingerprintSetup(String email, String password) async {
    if (!mounted) {
      widget.onLoginSuccess();
      return;
    }

    final bool? setupFingerprint = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? AppColors.headerDarkPine : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fingerprint,
                color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Setup Fingerprint Login',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Credentials Validated Successfully',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Would you like to enable fingerprint authentication for quicker, secure 1-tap logins to the CRM portal on this device?',
              style: TextStyle(
                fontSize: 12.5,
                color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Not Now',
              style: TextStyle(
                color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.fingerprint, size: 18),
            label: const Text('Setup Fingerprint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPine,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (setupFingerprint == true) {
      final didScan = await BiometricAuthService.authenticateBiometricsOrPasscode(
        reason: 'Scan Fingerprint to enable quicker logins for $email',
      );
      if (didScan) {
        await TokenStorage().setFingerprintEnabledFor(
          email: email,
          enabled: true,
          password: password.isNotEmpty ? password : 'password',
        );
        final enrolled = await TokenStorage().getFingerprintEnrolledEmail();
        final refreshedAccounts = await TokenStorage().readSavedAccounts();
        if (mounted) {
          setState(() {
            _enrolledFingerprintEmail = enrolled;
            _savedAccounts = refreshedAccounts;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint authentication enabled for quicker logins!'),
              backgroundColor: AppColors.primaryPine,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint setup was not completed.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    if (mounted) {
      widget.onLoginSuccess();
    }
  }

  Future<String?> _showGoogleAccountPicker() async {
    final List<String> candidateEmails = [];
    for (final acc in _savedAccounts) {
      if (!candidateEmails.contains(acc.email)) {
        candidateEmails.add(acc.email);
      }
    }
    for (final entry in AppState.userDirectory.entries) {
      if (!candidateEmails.contains(entry.key)) {
        candidateEmails.add(entry.key);
      }
    }

    final TextEditingController customGoogleController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        title: Row(
          children: [
            _buildGoogleLogo(),
            const SizedBox(width: 10),
            Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an account to continue to Innoveity CRM',
                style: TextStyle(
                  fontSize: 12.5,
                  color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidateEmails.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final email = candidateEmails[i];
                    final profile = AppState.findEmployeeInCrm(email);
                    final isCustomCompany = profile?.hasCustomCompanyEmail ?? email.endsWith('@enterprise-crm.com');
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isCustomCompany
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.15),
                        child: Icon(
                          isCustomCompany ? Icons.business_rounded : Icons.person_outline,
                          size: 16,
                          color: isCustomCompany ? Colors.orange : Colors.blue,
                        ),
                      ),
                      title: Text(
                        profile?.name ?? email,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                        ),
                      ),
                      trailing: isCustomCompany
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Custom Mail',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(ctx).pop(email),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customGoogleController,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Or enter other Google account...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    onPressed: () {
                      final val = customGoogleController.text.trim();
                      if (val.isNotEmpty) {
                        Navigator.of(ctx).pop(val);
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  final v = val.trim();
                  if (v.isNotEmpty) {
                    Navigator.of(ctx).pop(v);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    String? emailToVerify = _emailController.text.trim();
    if (emailToVerify.isEmpty) {
      emailToVerify = await _showGoogleAccountPicker();
      if (emailToVerify == null || emailToVerify.isEmpty) {
        return; // User canceled
      }
    }

    final validation = AppState.validateGoogleSignIn(emailToVerify);

    if (!validation.canSync) {
      if (!mounted) return;

      if (validation.errorTitle == 'Custom Company Mail Assigned') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Custom Company Mail Assigned',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Text(
                validation.errorMessage ??
                    'A custom company email is assigned to this account. Security policy requires logging in using your username/email and password.',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final customEmail = validation.assignedCompanyEmail ?? emailToVerify;
                  _emailController.text = customEmail!;
                  _passwordController.clear();
                  _passwordFocusNode.requestFocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to company email ($customEmail). Enter your password to log in.'),
                      duration: const Duration(seconds: 3),
                      backgroundColor: AppColors.primaryPine,
                    ),
                  );
                },
                child: const Text('Login with Username & Password'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad, color: Colors.red),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    validation.errorTitle ?? 'Google Sign-In Denied',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: Text(
              validation.errorMessage ??
                  'Google Sign-In only syncs when company email and employee or intern email match the same.',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Validation succeeded: company email and employee/intern email match the exact same!
    _emailController.text = emailToVerify;

    // Look for matching saved password or enterprise default
    final savedAccount = _savedAccounts.where(
      (a) => a.email.trim().toLowerCase() == emailToVerify!.trim().toLowerCase(),
    ).firstOrNull;
    final passwordToUse = savedAccount?.password ?? '123456';
    _passwordController.text = passwordToUse;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Workspace account synced for $emailToVerify'),
          backgroundColor: AppColors.primaryPine,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Execute authenticated login
    if (widget.onLoginWithCredentials != null) {
      final success = await widget.onLoginWithCredentials!(emailToVerify, passwordToUse);
      if (success) {
        final isFingerprintSetup = await TokenStorage().isFingerprintEnabledFor(emailToVerify);
        if (!isFingerprintSetup && mounted) {
          await _promptFingerprintSetup(emailToVerify, passwordToUse);
        } else if (mounted) {
          widget.onLoginSuccess();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google authentication sync failed. Please log in with password.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (mounted) {
      widget.onLoginSuccess();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.trim().isEmpty && _savedAccounts.isNotEmpty) {
      _emailController.text = _savedAccounts.first.email;
      if (_passwordController.text.trim().isEmpty) {
        _passwordController.text = _savedAccounts.first.password;
      }
    }
    final inputEmail = _emailController.text.trim();
    final inputPassword = _passwordController.text.trim();

    if (inputEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your work email or employee ID.')),
      );
      return;
    }

    if (widget.onLoginWithCredentials != null) {
      final success = await widget.onLoginWithCredentials!(
        inputEmail,
        inputPassword,
      );
      if (success) {
        if (_savePassword && inputPassword.isNotEmpty) {
          await TokenStorage().saveAccountCredential(
            email: inputEmail,
            password: inputPassword,
          );
        } else {
          await TokenStorage().saveUserLogin(inputEmail);
        }
        final refreshed = await TokenStorage().readSavedAccounts();
        final enrolled = await TokenStorage().getFingerprintEnrolledEmail();
        if (mounted) {
          setState(() {
            _savedAccounts = refreshed;
            _enrolledFingerprintEmail = enrolled;
          });
        }

        // Check if this validated account has fingerprint configured
        final isFingerprintSetup = await TokenStorage().isFingerprintEnabledFor(inputEmail);
        if (!isFingerprintSetup) {
          await _promptFingerprintSetup(inputEmail, inputPassword);
          return;
        } else {
          widget.onLoginSuccess();
          return;
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid user credentials. Please check your email/employee ID or password.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (_savePassword && inputPassword.isNotEmpty) {
        await TokenStorage().saveAccountCredential(
          email: inputEmail,
          password: inputPassword,
        );
      } else {
        await TokenStorage().saveUserLogin(inputEmail);
      }
      final refreshed = await TokenStorage().readSavedAccounts();
      final enrolled = await TokenStorage().getFingerprintEnrolledEmail();
      if (mounted) {
        setState(() {
          _savedAccounts = refreshed;
          _enrolledFingerprintEmail = enrolled;
        });
      }
      final isFingerprintSetup = await TokenStorage().isFingerprintEnabledFor(inputEmail);
      if (!isFingerprintSetup) {
        await _promptFingerprintSetup(inputEmail, inputPassword);
        return;
      }
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Top App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.primaryContainer,
                                child: const Icon(Icons.business_center_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Innoveity',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: widget.isDarkMode
                                    ? AppColors.borderEmerald
                                    : AppColors.primaryPine,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ENTERPRISE PORTAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: widget.isDarkMode
                                    ? AppColors.textLightMuted
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onToggleTheme,
                          icon: Icon(
                            widget.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            size: 20,
                          ),
                          tooltip: 'Toggle Theme',
                        ),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contacting Enterprise IT Helpdesk...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.help_outline, size: 20),
                          tooltip: 'Help',
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 16),

                // Segmented Controller
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? AppColors.cardDark
                        : const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white10
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _authModeIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _authModeIndex == 0
                                  ? (widget.isDarkMode
                                      ? AppColors.primaryPine
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _authModeIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: _authModeIndex == 0
                                      ? (widget.isDarkMode ? Colors.white : AppColors.primaryPine)
                                      : (widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Work Email',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _authModeIndex == 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: _authModeIndex == 0
                                          ? (widget.isDarkMode ? Colors.white : AppColors.primaryPine)
                                          : (widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _authModeIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _authModeIndex == 1
                                  ? (widget.isDarkMode
                                      ? AppColors.primaryPine
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _authModeIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dialpad,
                                  size: 18,
                                  color: _authModeIndex == 1
                                      ? (widget.isDarkMode ? Colors.white : AppColors.primaryPine)
                                      : (widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'PIN / Passcode',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _authModeIndex == 1
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: _authModeIndex == 1
                                          ? (widget.isDarkMode ? Colors.white : AppColors.primaryPine)
                                          : (widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Canvas
                Expanded(
                  child: SingleChildScrollView(
                    child: _authModeIndex == 0
                        ? _buildEmailForm(context, theme)
                        : _buildPinKeypad(context, theme),
                  ),
                ),

                // Footer
                Column(
                  children: [
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 14,
                            color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '256-bit SSL • Single Sign-On • IT Helpdesk Support',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign In',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in with your enterprise credentials to manage shifts, timesheets, and deliverables.',
          style: TextStyle(
            fontSize: 13,
            color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),

        // Saved Accounts Quick Selector (Multiple Saved Accounts)
        if (_savedAccounts.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 14,
                      color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Saved Accounts (${_savedAccounts.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Tap to autofill',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _savedAccounts.map((account) {
                final isCurrent = _emailController.text.trim().toLowerCase() == account.email.toLowerCase();
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectSavedAccount(account),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryPine.withValues(alpha: widget.isDarkMode ? 0.35 : 0.1)
                              : (widget.isDarkMode ? AppColors.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? (widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine)
                                : (widget.isDarkMode ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                            width: isCurrent ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 15,
                              color: isCurrent
                                  ? (widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine)
                                  : (widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  account.email,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    color: isCurrent
                                        ? (widget.isDarkMode ? AppColors.emeraldMintText : AppColors.primaryPine)
                                        : (widget.isDarkMode ? Colors.white : AppColors.textDark),
                                  ),
                                ),
                                Text(
                                  '••••••••',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                    color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _deleteSavedAccount(account.email),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Company Email
        Text(
          'Company Email Address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          style: TextStyle(
            fontSize: 14,
            color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.mail_outline,
              size: 20,
              color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
            ),
            suffixIcon: _savedAccounts.isNotEmpty
                ? PopupMenuButton<SavedAccountCredential>(
                    icon: Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      size: 20,
                      color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                    ),
                    tooltip: 'Select Saved Account',
                    onSelected: _selectSavedAccount,
                    itemBuilder: (ctx) => _savedAccounts.map((acc) {
                      return PopupMenuItem<SavedAccountCredential>(
                        value: acc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_person_outlined,
                              size: 16,
                              color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '••••••••',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: widget.isDarkMode ? AppColors.textLightMuted : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : null,
            hintText: 'name@company.com',
            hintStyle: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
            ),
            filled: true,
            fillColor: widget.isDarkMode
                ? AppColors.cardDark
                : AppColors.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset link sent to company email.'),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          style: TextStyle(
            fontSize: 14,
            color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              size: 20,
              color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            hintText: 'Enter password',
            hintStyle: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
            ),
            filled: true,
            fillColor: widget.isDarkMode
                ? AppColors.cardDark
                : AppColors.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Checkboxes: Save Password & Remember Device
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _savePassword,
                  activeColor: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  onChanged: (val) => setState(() => _savePassword = val ?? true),
                ),
                Text(
                  'Save password',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
              ],
            ),
            if (_emailController.text.trim().isNotEmpty && _passwordController.text.trim().isNotEmpty)
              TextButton.icon(
                onPressed: _saveCurrentCredentialsManually,
                icon: Icon(
                  Icons.bookmark_add_outlined,
                  size: 14,
                  color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                ),
                label: Text(
                  'Save Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),

        Row(
          children: [
            Checkbox(
              value: _rememberDevice,
              activeColor: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
              onChanged: (val) => setState(() => _rememberDevice = val ?? true),
            ),
            Expanded(
              child: Text(
                'Remember this device for 30 days',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPine,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Sign In to Workspace',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'OR QUICK UNLOCK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Quick Passcode button
        OutlinedButton(
          onPressed: _handleBiometricOrPasscodeAuth,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            side: BorderSide(
              color: widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderEmerald,
            ),
            backgroundColor: widget.isDarkMode ? AppColors.cardDark : AppColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.headerDarkPine : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fingerprint,
                  color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fingerprint Quick Login',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                    Text(
                      _enrolledFingerprintEmail != null
                          ? 'Tap to unlock as $_enrolledFingerprintEmail'
                          : 'Login with credentials first to set up',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                _enrolledFingerprintEmail != null ? Icons.fingerprint : Icons.lock_outline,
                color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                size: 20,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Google Sign-In Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
              side: BorderSide(
                color: widget.isDarkMode ? AppColors.borderCardDark : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleLogo(),
                const SizedBox(width: 10),
                Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinKeypad(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Employee Profile Header
        Stack(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryPine, width: 2),
                color: AppColors.vibrantEmerald.withValues(alpha: 0.2),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.primaryPine,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryPine,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Employee Passcode',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        Text(
          'Enter PIN to unlock workspace',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode
                  ? AppColors.vibrantEmerald.withValues(alpha: 0.4)
                  : AppColors.borderEmerald,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_open,
                size: 12,
                color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
              ),
              const SizedBox(width: 4),
              Text(
                'DEVICE FAST UNLOCK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Enter 6-digit phone passcode',
          style: TextStyle(
            fontSize: 13,
            color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < _enteredPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine)
                    : Colors.transparent,
                border: Border.all(
                  color: isFilled
                      ? (widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine)
                      : (widget.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight),
                  width: 2,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // Keypad Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            if (index == 9) {
              // Face ID / Biometrics
              return InkWell(
                onTap: _handleBiometricOrPasscodeAuth,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? AppColors.cardDark
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.face,
                    color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                    size: 28,
                  ),
                ),
              );
            }
            if (index == 10) {
              return _buildKeypadButton('0');
            }
            if (index == 11) {
              return InkWell(
                onTap: () {
                  if (_enteredPin.isNotEmpty) {
                    setState(() {
                      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? AppColors.cardDark
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                ),
              );
            }
            return _buildKeypadButton('${index + 1}');
          },
        ),

        const SizedBox(height: 16),

        TextButton.icon(
          onPressed: () => setState(() => _authModeIndex = 0),
          icon: Icon(
            Icons.key,
            size: 16,
            color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
          ),
          label: Text(
            'Use password instead',
            style: TextStyle(
              color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_enteredPin.length < 6) {
            _enteredPin += digit;
          }
        });
        if (_enteredPin.length == 4 || _enteredPin.length == 6) {
          _handleSignIn();
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? AppColors.cardDark
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = radius * 0.44;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Red: Top arc
    canvas.drawArc(rect, -3.14159 * 0.85, 3.14159 * 0.7, false, paintRed);
    // Yellow: Left arc
    canvas.drawArc(rect, 3.14159 * 0.55, 3.14159 * 0.6, false, paintYellow);
    // Green: Bottom arc
    canvas.drawArc(rect, 3.14159 * 0.05, 3.14159 * 0.5, false, paintGreen);
    // Blue: Right bottom arc
    canvas.drawArc(rect, -3.14159 * 0.15, 3.14159 * 0.2, false, paintBlue);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(center.dx - 1, center.dy - strokeWidth / 2, radius, strokeWidth);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
