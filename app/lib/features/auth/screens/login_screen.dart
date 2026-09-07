import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/breakpoint_logo.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/overlays/app_toast.dart';
import '../../../core/utils/data_populator.dart';
import '../providers/auth_provider.dart';
import '../../../core/errors/error_mapper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isSignUp) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!validEmail) {
      AppToast.show(context,
          message: 'Enter a valid email address.', type: ToastType.error);
      return;
    }
    if (password.isEmpty || (isSignUp && password.length < 8)) {
      AppToast.show(
        context,
        message: isSignUp
            ? 'Choose a password with at least 8 characters.'
            : 'Enter your password.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isSignUp) {
        await ref
            .read(authControllerProvider.notifier)
            .signUpWithEmailAndPassword(email, password);
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithEmailAndPassword(email, password);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context,
            message: ErrorMapper.userMessage(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      AppToast.show(context,
          message: 'Please enter your email to reset your password',
          type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email);
      if (mounted) {
        AppToast.show(context,
            message: 'Password reset email sent!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context,
            message: ErrorMapper.userMessage(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bgColor = AppTheme.backgroundColor(context);
    final cardColor = AppTheme.cardColor(context);
    final primaryTextColor = AppTheme.primaryTextColor(context);
    final secondaryTextColor = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final inputFill = isDark ? const Color(0xFF1C1C28) : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Breakpoint Logo Header
                const BreakpointLogo(
                  fontSize: 28,
                  showLockup: true,
                  showTagline: true,
                ),
                const SizedBox(height: 32),

                // Email Authentication Input Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Field
                      Text(
                        'Email Address',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'name@organization.com',
                          hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 14),
                          filled: true,
                          fillColor: inputFill,
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppTheme.primaryOrange, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryOrange, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 14),
                          filled: true,
                          fillColor: inputFill,
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppTheme.primaryOrange, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: secondaryTextColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _obscurePassword = !_obscurePassword);
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryOrange, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _resetPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons Row (Sign Up & Sign In)
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Sign Up',
                              onPressed:
                                  _isLoading ? () {} : () => _submit(true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: () => _submit(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dev Mode Database Population
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  TextButton.icon(
                    icon: const Icon(Icons.developer_mode,
                        color: AppTheme.primaryOrange, size: 18),
                    label: const Text(
                      'DEV: Populate Database',
                      style: TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await DataPopulator.populateDatabase();
                              if (!context.mounted) return;
                              AppToast.show(context,
                                  message:
                                      'Database populated successfully!',
                                  type: ToastType.success);
                            } catch (e) {
                              if (!context.mounted) return;
                              AppToast.show(context,
                                  message:
                                      "We couldn't prepare the test data.",
                                  type: ToastType.error);
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
