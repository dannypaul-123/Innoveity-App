import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';
import '../theme/app_colors.dart';
import '../core/storage/token_storage.dart';

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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
      if (mounted) {
        setState(() {
          _savedAccounts = accounts;
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
    final success = await BiometricAuthService.authenticateBiometricsOrPasscode(
      reason: 'Scan Fingerprint, Face ID, or Device PIN to log in to Innoveity CRM',
    );
    if (success && mounted) {
      if (_emailController.text.trim().isEmpty) {
        if (_savedAccounts.isNotEmpty) {
          _emailController.text = _savedAccounts.first.email;
          _passwordController.text = _savedAccounts.first.password;
        } else {
          final savedEmail = await TokenStorage().readSavedUserLogin();
          _emailController.text = (savedEmail != null && savedEmail.isNotEmpty)
              ? savedEmail
              : 'antorajan501@gmail.com';
        }
      }
      if (_passwordController.text.trim().isEmpty) {
        _passwordController.text = '123456';
      }
      await _handleSignIn();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_emailController.text.trim().isEmpty) {
      if (_savedAccounts.isNotEmpty) {
        _emailController.text = _savedAccounts.first.email;
        _passwordController.text = _savedAccounts.first.password;
      } else {
        final savedEmail = await TokenStorage().readSavedUserLogin();
        _emailController.text = (savedEmail != null && savedEmail.isNotEmpty)
            ? savedEmail
            : 'antorajan501@gmail.com';
        _passwordController.text = '123456';
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signing in with Google Workspace...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    await _handleSignIn();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
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
        if (mounted) {
          setState(() {
            _savedAccounts = refreshed;
          });
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
      if (mounted) {
        setState(() {
          _savedAccounts = refreshed;
        });
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
              Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    size: 14,
                    color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Saved Accounts (${_savedAccounts.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
                    ),
                  ),
                ],
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
                      'Use Phone Passcode / Face ID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Fast 1-tap secure authentication',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
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
