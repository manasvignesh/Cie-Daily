import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

class BreakpointShareSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String url,
    required String shareText,
    required String qrInstruction,
    String? connectionCode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ShareSheet(
        title: title,
        url: url,
        shareText: shareText,
        qrInstruction: qrInstruction,
        connectionCode: connectionCode,
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({
    required this.title,
    required this.url,
    required this.shareText,
    required this.qrInstruction,
    this.connectionCode,
  });

  final String title;
  final String url;
  final String shareText;
  final String qrInstruction;
  final String? connectionCode;

  @override
  Widget build(BuildContext context) {
    final text = AppTheme.primaryTextColor(context);
    final secondary = AppTheme.secondaryTextColor(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        gradient: AppTheme.raisedSurfaceGradient(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border:
            Border(top: BorderSide(color: AppTheme.materialEdgeColor(context))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: secondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: TextStyle(
                    color: text,
                    fontFamily: 'Sora',
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            _Action(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () => SharePlus.instance
                    .share(ShareParams(text: '$shareText\n$url'))),
            _Action(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onTap: () => _copy(context, url, 'Link copied')),
            _Action(
                icon: Icons.qr_code_2_rounded,
                label: 'Show QR',
                onTap: () => _showQr(context)),
            if (connectionCode != null)
              _Action(
                  icon: Icons.password_rounded,
                  label: 'Copy connection code',
                  onTap: () => _copy(
                      context, connectionCode!, 'Connection code copied')),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showQr(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.elevatedSurfaceColor(context),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.white,
                child: QrImageView(
                    data: url, size: 230, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(qrInstruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('BREAKPOINT',
                  style: TextStyle(
                      color: AppTheme.accentColor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppTheme.accentColor(context)),
        title: Text(label,
            style: TextStyle(
                color: AppTheme.primaryTextColor(context),
                fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppTheme.secondaryTextColor(context)),
        onTap: onTap,
      );
}
