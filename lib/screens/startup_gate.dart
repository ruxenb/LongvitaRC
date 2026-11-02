import 'package:flutter/material.dart';

import '../firebase/firebase_bootstrap.dart';
import '../theme/app_theme.dart';
import '../widgets/longvita_widgets.dart';

/// Runs Firebase start-up before the dependency tree exists (S3-1).
///
/// Shows a loading state, then either [buildReadyApp] or a start-up error
/// with retry. A failed start never continues into screens that would call
/// Firebase SDK singletons.
class StartupGate extends StatefulWidget {
  final Future<BootstrapResult> Function() initialize;

  /// Builds the provider tree and app. Called once, after success.
  final Future<Widget> Function() buildReadyApp;

  const StartupGate({
    super.key,
    required this.initialize,
    required this.buildReadyApp,
  });

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Widget? _ready;
  BootstrapFailed? _failure;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _failure = null;
    });
    final result = await widget.initialize();
    if (!mounted) return;
    switch (result) {
      case BootstrapReady():
        final app = await widget.buildReadyApp();
        if (!mounted) return;
        setState(() {
          _ready = app;
          _running = false;
        });
      case BootstrapFailed():
        debugPrint('Firebase start-up failed: ${result.code} ${result.error}');
        setState(() {
          _failure = result;
          _running = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    if (ready != null) return ready;

    final failure = _failure;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pageMargin),
              child: failure == null
                  ? const LoadingView(
                      title: 'Đang khởi động Longvita',
                      message: 'Đang kết nối dịch vụ đám mây…',
                    )
                  : ErrorView(
                      title: 'Không thể khởi động ứng dụng',
                      message: failure.isConfigurationMissing
                          ? 'Bản cài đặt này chưa có cấu hình Firebase. '
                              'Vui lòng dùng bản build đã cấu hình dự án.'
                          : 'Không kết nối được dịch vụ đám mây. '
                              'Kiểm tra kết nối mạng rồi thử lại.',
                      retryLabel: 'Thử lại',
                      onRetry: _running ? null : _start,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
