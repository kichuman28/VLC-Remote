import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/vlc_provider.dart';
import 'remote_screen.dart';
import 'instructions_screen.dart';

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
                      const SizedBox(height: 24),

                      // Instructions (Moved for better visibility)
                      _buildInstructionsLink(theme),
                      const SizedBox(height: 32),

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
        SizedBox(
          width: 200, // Increased logo size
          height: 160, // Increased logo size
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
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
        // IP Address
        _buildTextField(
          theme: theme,
          label: 'IPv4 Address',
          hint: '192.168.1.100',
          controller: _hostController,
          icon: Icons.laptop_mac_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
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
        const SizedBox(height: 20),

        // Port
        _buildTextField(
          theme: theme,
          label: 'Port',
          hint: '8080',
          controller: _portController,
          icon: Icons.tag_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter port';
            final port = int.tryParse(value);
            if (port == null || port < 1 || port > 65535) {
              return 'Invalid port';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password
        _buildTextField(
          theme: theme,
          label: 'Password',
          hint: 'VLC Web Interface password',
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _testConnection(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
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

  Widget _buildInstructionsLink(ThemeData theme) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstructionsScreen()),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(
          Icons.help_outline_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        label: Text(
          'How do I set this up?',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, size: 20),
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: suffixIcon,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          validator: validator,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
