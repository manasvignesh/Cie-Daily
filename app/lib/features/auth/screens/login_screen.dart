import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/overlays/app_toast.dart';
import '../../../core/utils/data_populator.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isSignUp) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      AppToast.show(context, message: 'Please enter a valid email and password', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isSignUp) {
        await ref.read(authControllerProvider.notifier).signUpWithEmailAndPassword(email, password);
      } else {
        await ref.read(authControllerProvider.notifier).signInWithEmailAndPassword(email, password);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.show(context, message: 'Please enter your email to reset your password', type: ToastType.error);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
      if (mounted) {
        AppToast.show(context, message: 'Password reset email sent!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  height: 64,
                  width: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to\nProject Catalyst',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in with your email and password.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Sign Up',
                      onPressed: _isLoading ? () {} : () => _submit(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: () => _submit(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
              ),
              if (const bool.fromEnvironment('dart.vm.product') == false)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.developer_mode, color: Colors.red),
                    label: const Text('DEV: Populate Database', style: TextStyle(color: Colors.red)),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await DataPopulator.populateDatabase();
                              if (mounted) {
                                AppToast.show(context, message: 'Database populated successfully!', type: ToastType.success);
                              }
                            } catch (e) {
                              if (mounted) {
                                AppToast.show(context, message: 'Error: $e', type: ToastType.error);
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
