import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoginMode = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _rememberMe = box.get('remember_me', defaultValue: false) as bool;
    if (_rememberMe) {
      _emailController.text =
          box.get('saved_email', defaultValue: '') as String;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveRememberMe() async {
    final box = Hive.box('settings');
    await box.put('remember_me', _rememberMe);
    if (_rememberMe) {
      await box.put('saved_email', _emailController.text.trim());
    } else {
      await box.delete('saved_email');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success) {
      await _saveRememberMe();
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Giriş başarısız'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      await _saveRememberMe();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Hoş geldiniz.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Kayıt başarısız'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();

    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Google ile giriş başarısız'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF060D1B),
              Color(0xFF0D1829),
              Color(0xFF112244),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'LezzetPot',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tariflerin dünyasına hoş geldin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Tab Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _isLoginMode = true),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _isLoginMode
                                          ? AppTheme.primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _isLoginMode
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      'Giriş Yap',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isLoginMode
                                            ? Colors.white
                                            : AppTheme.textSecondary
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _isLoginMode = false),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_isLoginMode
                                          ? AppTheme.primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: !_isLoginMode
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      'Kayıt Ol',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: !_isLoginMode
                                            ? Colors.white
                                            : AppTheme.textSecondary
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (!_isLoginMode) ...[
                          _buildInputField(
                            controller: _usernameController,
                            hintText: 'Kullanıcı adı',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kullanıcı adı gerekli';
                              }
                              if (value.length < 3) {
                                return 'En az 3 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildInputField(
                          controller: _emailController,
                          hintText: 'E-posta adresi',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-posta gerekli';
                            }
                            if (!value.contains('@')) {
                              return 'Geçerli bir e-posta girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Şifre',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textTertiary
                                  .withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre gerekli';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı';
                            }
                            return null;
                          },
                        ),

                        if (!_isLoginMode) ...[
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: 'Şifre tekrar',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textTertiary
                                    .withValues(alpha: 0.6),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre tekrarı gerekli';
                              }
                              if (value != _passwordController.text) {
                                return 'Şifreler eşleşmiyor';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Beni Hatırla
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                activeColor: AppTheme.primaryColor,
                                side: BorderSide(
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Text(
                                'Beni Hatırla',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            if (_isLoginMode) ...[
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Şifremi Unuttum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : (_isLoginMode
                                    ? _handleLogin
                                    : _handleRegister),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'veya',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed:
                                isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://www.google.com/favicon.ico',
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isLoginMode
                                      ? 'Google ile Giriş Yap'
                                      : 'Google ile Kayıt Ol',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          _isLoginMode
                              ? 'Devam ederek Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmiş olursunuz.'
                              : 'Kayıt olarak Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmiş olursunuz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.textTertiary.withValues(alpha: 0.6),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}
