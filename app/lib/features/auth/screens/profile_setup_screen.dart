import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../user/data/firebase_user_repository.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();
    final year = int.tryParse(_yearController.text.trim());
    if (name.isEmpty ||
        department.isEmpty ||
        year == null ||
        year < 1 ||
        year > 4) {
      setState(() {
        _formError = year == null || year < 1 || year > 4
            ? 'Enter a valid study year from 1 to 4.'
            : 'Complete all fields before continuing.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _formError = null;
    });
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw const AppException(
          code: AppErrorCode.unauthenticated,
          userMessage: 'Your session has expired. Sign in again to continue.',
        );
      }
      await ref.read(userRepositoryProvider).createUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            fullName: name,
            department: department,
            yearOfStudy: year,
          );
      await ref.read(authControllerProvider.notifier).retryInitialization();
    } catch (e) {
      if (mounted) {
        setState(() => _formError = ErrorMapper.userMessage(e));
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Avatar Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 44,
                      color: AppTheme.primaryOrange,
                    ),
                  ).animate().scale(
                      delay: 150.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 24),
                Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                    letterSpacing: -0.5,
                    color: primaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  'Let others know who you are on campus.',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),

                // Form Container
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
                      _buildFieldLabel('Full Name', primaryTextColor),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'e.g. Manas Vignesh',
                        icon: Icons.person_rounded,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputFill: inputFill,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Department', primaryTextColor),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _departmentController,
                        hint: 'e.g. CSE or ECE',
                        icon: Icons.school_rounded,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputFill: inputFill,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Year of Study (1–4)', primaryTextColor),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _yearController,
                        hint: 'e.g. 4',
                        icon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.number,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputFill: inputFill,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),

                const SizedBox(height: 28),
                if (_formError != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _formError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                PrimaryButton(
                  text: 'Save and Continue',
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _saveProfile,
                ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.08),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color inputFill,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: primaryTextColor, fontSize: 15, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 14),
        filled: true,
        fillColor: inputFill,
        prefixIcon: Icon(icon, color: AppTheme.primaryOrange, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
        ),
      ),
    );
  }
}
