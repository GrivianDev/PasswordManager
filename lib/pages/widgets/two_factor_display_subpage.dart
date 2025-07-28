import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ntp/ntp.dart';
import 'package:passwordmanager/engine/config/app_config.dart';
import 'package:passwordmanager/engine/two_factor_token.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

// This is the NTP time offset to calculate how much off the local system time is.
Duration? _ntpOffset;

class TwoFactorDisplaySubpage extends StatefulWidget {
  const TwoFactorDisplaySubpage({super.key, required this.twoFactorSecret});

  final TOTPSecret twoFactorSecret;

  @override
  State<TwoFactorDisplaySubpage> createState() => _TwoFactorDisplaySubpageState();
}

class _TwoFactorDisplaySubpageState extends State<TwoFactorDisplaySubpage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late String _currentCode;
  bool _ntpLoaded = false;

  /// Synced time with fetched ntp offset. Falls back to normal local device time.
  DateTime _getSyncedTime() {
    final now = DateTime.now().toUtc();
    return _ntpOffset != null ? now.subtract(_ntpOffset!) : now;
  }

  /// Async getter and setup function for fetching time offset of local device.
  Future<void> _initWithNtp() async {
    if (_ntpOffset == null) {
      try {
        DateTime ntpDate = await NTP.now(lookUpAddress: Config.ntpTimeSyncDomain, timeout: Duration(seconds: 5));
        DateTime localDate = DateTime.now().toUtc();
        _ntpOffset = localDate.difference(ntpDate.toUtc());
      } catch (_) {
        _ntpOffset = null;
      }
    }

    final DateTime now = _getSyncedTime();
    final double currentProgress = (now.millisecondsSinceEpoch % 30000) / 30000;

    // Initialize and start animation
    _currentCode = widget.twoFactorSecret.generateTOTPCode(timestamp: now);
    _animController.value = currentProgress;
    _animController.forward();

    setState(() {
      _ntpLoaded = true;
    });
  }

  // Copies 2FA code to the clipboard.
  Future<void> _copyClicked(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _currentCode));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Copied 2FA code to clipboard'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() => setState(() {
          /* Render updates*/
        }));

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Update code and restart animation
        final DateTime now = _getSyncedTime();
        _currentCode = widget.twoFactorSecret.generateTOTPCode(timestamp: DateTime.now().toUtc());
        _animController.forward(from: 0.0);
      }
    });

    _initWithNtp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ntpLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultPageBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
              onPressed: () => _copyClicked(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Text(
                  _currentCode.replaceAllMapped(RegExp(r'.{1,3}'), (match) => '${match.group(0)} ').trimRight(),
                  style: TextStyle(fontSize: 35.0, letterSpacing: 1.0),
                ),
              )),
          const SizedBox(height: 15.0),
          SizedBox(
            width: 250,
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: 1.0 - _animController.value,
                minHeight: 10,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                color: 1.0 - _animController.value < 0.2 ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 15.0),
          Text("${((1.0 - _animController.value) * 30).ceil()}s remaining"),
          if (_ntpOffset == null) ...[
            const SizedBox(height: 15.0),
            IconButton(
              icon: const Icon(Icons.warning_amber, color: Colors.deepOrange, size: 30),
              onPressed: () => Notify.dialog(
                context: context,
                type: NotificationType.error,
                title: 'Caution: Using local device time.',
                content: const Text(
                  'This app was not able to perform time synchronization. As fallback, local device time is used for 2FA code generation, which can be inaccurate.',
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}
