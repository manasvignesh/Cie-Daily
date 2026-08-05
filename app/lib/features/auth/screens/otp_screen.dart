import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/overlays/app_toast.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppToast.show(context, message: 'Please enter a 6-digit code', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(widget.email, otp);
      // On success, the AuthProvider stream will update and GoRouter will redirect automatically
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Invalid code. Try again.', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Code',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  border: UnderlineInputBorder(),
                ),
                onChanged: (val) {
                  if (val.length == 6) _verify();
                },
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Verify',
                isLoading: _isLoading,
                onPressed: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
