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
      backgroundColor: const Color(0xFF09090D),
      body: Stack(
        children: [
          // Background ambient orange light glows
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5A1F).withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF8A00).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Logo Box
                    Container(
                      height: 84,
                      width: 84,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A00), Color(0xFFFF5A1F), Color(0xFF1E1E26)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5A1F).withOpacity(0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF0D0D14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/icons/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Header Text
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFFFE0D3)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        'Welcome to Cie Daily',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stay Informed. Stay Ahead.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9EA5),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Glassmorphic Input Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131C).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              color: Color(0xFFD0D0D5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'name@organization.com',
                              hintStyle: const TextStyle(color: Color(0xFF646470), fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFF1C1C28),
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF8A00), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF5A1F), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFFD0D0D5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(color: Color(0xFF646470), fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFF1C1C28),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF8A00), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF8E8E9A),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF5A1F), width: 1.5),
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
                                  color: Color(0xFFFF8A00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  text: 'Sign Up',
                                  onPressed: _isLoading ? () {} : () => _submit(true),
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
                    const SizedBox(height: 28),

                    // Divider Or
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.08))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Color(0xFF6E6E7A), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.08))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Sign In Pill Button
                    InkWell(
                      onTap: _isLoading ? null : _signInWithGoogle,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161622),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFF4285F4), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DEV Mode Button (if non-product)
                    if (const bool.fromEnvironment('dart.vm.product') == false)
                      TextButton.icon(
                        icon: const Icon(Icons.developer_mode, color: Color(0xFFFF5A1F), size: 18),
                        label: const Text(
                          'DEV: Populate Database',
                          style: TextStyle(color: Color(0xFFFF8A00), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
