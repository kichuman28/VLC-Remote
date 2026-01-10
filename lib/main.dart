import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/vlc_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/remote_screen.dart';
import 'utils/app_theme.dart';

/// VLC Remote
///
/// A minimal, fast, ad-free VLC Remote mobile app that controls
/// VLC Media Player using only VLC's built-in Web Interface.
///
/// Designed for couch usage - controlling VLC on a laptop
/// connected to a TV.

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation to portrait for consistent TV remote experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const VlcRemoteApp());
}

class VlcRemoteApp extends StatelessWidget {
  const VlcRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VlcProvider(),
      child: MaterialApp(
        title: 'VLC Remote',
        debugShowCheckedModeBanner: false,

        // Dark theme by default for couch usage
        themeMode: ThemeMode.dark,

        // Minimalist theme with Manrope font
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        // App entry point
        home: const AppEntryPoint(),
      ),
    );
  }
}

/// App Entry Point
///
/// Determines whether to show setup or remote screen
/// based on saved connection settings.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isLoading = true;
  bool _shouldAutoConnect = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final provider = context.read<VlcProvider>();

    // Load saved settings
    await provider.loadSettings();

    // Check if we have saved settings for auto-connect
    if (provider.hasSettings) {
      _shouldAutoConnect = true;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Auto-connect if we have saved settings
    if (_shouldAutoConnect) {
      await provider.connect(
        host: provider.host,
        port: provider.port,
        password: provider.password,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VlcProvider>(
      builder: (context, provider, _) {
        // If connected, show remote screen
        if (provider.isConnected) {
          return const RemoteScreen();
        }

        return const SetupScreen();
      },
    );
  }
}
