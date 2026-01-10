import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/vlc_provider.dart';
import 'remote_screen.dart';

/// Setup Screen
///
/// Clean, minimal setup for VLC connection.
/// Designed to be simple and approachable.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _passwordController = TextEditingController();

  bool _isTestingConnection = false;
  bool _isConnecting = false;
  String? _testResult;
  bool _testSuccess = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final provider = context.read<VlcProvider>();
    if (provider.hasSettings) {
      _hostController.text = provider.host;
      _portController.text = provider.port.toString();
      _passwordController.text = provider.password;
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    final provider = context.read<VlcProvider>();
    final error = await provider.testConnection(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 8080,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isTestingConnection = false;
      _testSuccess = error == null;
      _testResult = error ?? 'Connected successfully';
    });

    HapticFeedback.mediumImpact();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
    });

    final provider = context.read<VlcProvider>();
    await provider.connect(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 8080,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (provider.isConnected) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RemoteScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      setState(() {
        _isConnecting = false;
        _testResult = provider.errorMessage;
        _testSuccess = false;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Title
                      _buildHeader(theme),
                      const SizedBox(height: 48),

                      // Input Fields
                      _buildInputFields(theme),
                      const SizedBox(height: 24),

                      // Status Message
                      if (_testResult != null) ...[
                        _buildStatusMessage(theme),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      _buildActionButtons(theme),
                      const SizedBox(height: 32),

                      // Setup Instructions
                      _buildInstructions(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        // Title
        Text(
          'VLC Remote',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          'Control VLC from your couch',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields(ThemeData theme) {
    return Column(
      children: [
        // IP Address
        TextFormField(
          controller: _hostController,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'IPv4 Address',
            hintText: '192.168.1.100',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.laptop_mac_rounded, size: 20),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter your laptop\'s IP address';
            }
            final parts = value.split('.');
            if (parts.length != 4) {
              return 'Invalid IP format';
            }
            for (final part in parts) {
              final num = int.tryParse(part);
              if (num == null || num < 0 || num > 255) {
                return 'Invalid IP address';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Port
        TextFormField(
          controller: _portController,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Port',
            hintText: '8080',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.tag_rounded, size: 20),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter port';
            final port = int.tryParse(value);
            if (port == null || port < 1 || port > 65535) {
              return 'Invalid port';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password
        TextFormField(
          controller: _passwordController,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'VLC Web Interface password',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.lock_outline_rounded, size: 20),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _testConnection(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter your VLC password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStatusMessage(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _testSuccess
            ? const Color(0xFF00D4AA).withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _testSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            color: _testSuccess ? const Color(0xFF00D4AA) : theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _testResult!,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _testSuccess ? const Color(0xFF00D4AA) : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Test Connection
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isTestingConnection || _isConnecting ? null : _testConnection,
            child: _isTestingConnection
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                : Text('Test Connection'),
          ),
        ),
        const SizedBox(height: 12),

        // Connect
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isTestingConnection || _isConnecting ? null : _connect,
            child: _isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Connect'),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'How to enable VLC Web Interface',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1
          _buildInstructionStep(
            theme,
            '1',
            'Open Preferences',
            'In VLC, go to Tools → Preferences',
          ),

          // Step 2 - Important!
          _buildInstructionStep(
            theme,
            '2',
            'Show ALL Settings',
            'Look at the BOTTOM LEFT corner of the Preferences window. '
                'You\'ll see two radio buttons: "Simple" and "All". '
                'Click "All" to show advanced settings.',
            isImportant: true,
          ),

          // Step 3
          _buildInstructionStep(
            theme,
            '3',
            'Enable Web interface',
            'In the left sidebar, click "Interface" → "Main interfaces". '
                'In the right panel, check the "Web" checkbox.',
          ),

          // Step 4 - Important!
          _buildInstructionStep(
            theme,
            '4',
            'Set your password',
            'STILL in the left sidebar under "Main interfaces", '
                'click the arrow/triangle to EXPAND it, then click "Lua". '
                'Find "Lua HTTP" section and enter a password.',
            isImportant: true,
          ),

          // Step 5
          _buildInstructionStep(
            theme,
            '5',
            'Save & Restart',
            'Click "Save", then completely close and reopen VLC.',
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'To find your laptop\'s IPv4: Open Command Prompt, type "ipconfig"',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    ThemeData theme,
    String number,
    String title,
    String description, {
    bool isImportant = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isImportant
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isImportant ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isImportant) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Important',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
