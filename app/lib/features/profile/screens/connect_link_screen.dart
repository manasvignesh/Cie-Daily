import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../chat/data/chat_repository.dart';

class ConnectLinkScreen extends ConsumerStatefulWidget {
  const ConnectLinkScreen({super.key, required this.connectionCode});
  final String connectionCode;

  @override
  ConsumerState<ConnectLinkScreen> createState() => _ConnectLinkScreenState();
}

class _ConnectLinkScreenState extends ConsumerState<ConnectLinkScreen> {
  bool _working = false;
  String? _message;

  Future<void> _connect() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final message = await ref
          .read(chatRepositoryProvider)
          .sendConnectionRequest(widget.connectionCode);
      if (mounted) setState(() => _message = message);
    } on ConnectionCodeException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _message = 'Connection could not be completed.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt_rounded,
                  size: 46, color: AppTheme.accentColor(context)),
              const SizedBox(height: 18),
              Text(_message ?? 'Connect with this person on Breakpoint?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontFamily: 'Sora',
                      fontSize: 21,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Connection code ${widget.connectionCode}',
                  style:
                      TextStyle(color: AppTheme.secondaryTextColor(context))),
              const SizedBox(height: 24),
              if (_message == null)
                FilledButton.icon(
                    onPressed: _working ? null : _connect,
                    icon: _working
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Connect'))
              else
                TextButton(
                    onPressed: () => context.go('/chat'),
                    child: const Text('Go to Connections')),
            ],
          ),
        ),
      ),
    );
  }
}
