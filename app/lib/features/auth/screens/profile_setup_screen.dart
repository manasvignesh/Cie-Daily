import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../user/data/firebase_user_repository.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/errors/error_mapper.dart';
import '../../medha/models/medha_models.dart';
import '../../medha/providers/medha_preferences_provider.dart';
import '../../medha/widgets/medha_companion_selector.dart';
import '../../medha/widgets/medha_companion_sprite.dart';

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
  bool _showCompanionStep = false;
  bool _showCompanionIntro = false;
  MedhaCompanionType _selectedCompanion = MedhaCompanionType.kiro;

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
      _formError = null;
      _showCompanionStep = true;
    });
  }

  Future<void> _completeProfile(
    MedhaCompanionType companion, {
    required bool showIntro,
  }) async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();
    final year = int.parse(_yearController.text.trim());
    await ref
        .read(medhaPreferencesProvider.notifier)
        .selectCompanion(companion);
    if (showIntro) {
      setState(() => _showCompanionIntro = true);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
    }
    setState(() {
      _showCompanionIntro = false;
      _isLoading = true;
      _formError = null;
    });
    try {
      final user =
          await ref.read(authRepositoryProvider).waitForAuthenticatedUser();
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
    final inputFill =
        isDark ? const Color(0xFF1C1C28) : const Color(0xFFF2F2F7);

    if (_showCompanionStep) {
      return _buildCompanionStep(
        context,
        backgroundColor: bgColor,
        primaryTextColor: primaryTextColor,
        secondaryTextColor: secondaryTextColor,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
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

  Widget _buildCompanionStep(
    BuildContext context, {
    required Color backgroundColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final profile = _selectedCompanion.profile;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _showCompanionIntro
              ? Center(
                  key: const ValueKey('medha-intro'),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MedhaCompanionSprite(
                          companion: _selectedCompanion,
                          state: MedhaBehaviorState.curious,
                          size: 190,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          profile.name,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '“Let’s find something worth knowing.”',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  key: const ValueKey('medha-selection'),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Back to profile',
                          onPressed: _isLoading
                              ? null
                              : () =>
                                  setState(() => _showCompanionStep = false),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your MEDHA companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Same intelligence. Different spirits.\nChoose the one that feels like you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 26),
                      MedhaCompanionSelector(
                        selected: _selectedCompanion,
                        onSelected: (value) =>
                            setState(() => _selectedCompanion = value),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Continue with ${profile.name}',
                        isLoading: _isLoading,
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () => _completeProfile(
                          _selectedCompanion,
                          showIntro: true,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => _completeProfile(
                                  MedhaCompanionType.kiro,
                                  showIntro: false,
                                ),
                        child: const Text('Choose later'),
                      ),
                      if (_formError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
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
      style:
          TextStyle(color: primaryTextColor, fontSize: 15, fontFamily: 'Inter'),
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
