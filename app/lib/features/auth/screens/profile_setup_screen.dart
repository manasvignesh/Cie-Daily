import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/data/firebase_user_repository.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/buttons/primary_button.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _departmentController.text.isEmpty || _yearController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref.read(userRepositoryProvider).createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          fullName: _nameController.text.trim(),
          department: _departmentController.text.trim(),
          yearOfStudy: int.tryParse(_yearController.text.trim()) ?? 1,
        );
        // Invalidate auth provider to trigger re-evaluation of routing state
        ref.invalidate(authControllerProvider);
      }
    } catch (e) {
      // Show error
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text('Complete Profile', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 12),
                Text('Let others know who you are.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Department (e.g., CSE)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year of Study (1-4)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'Save and Continue',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
