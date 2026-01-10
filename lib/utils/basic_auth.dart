import 'dart:convert';

/// Basic Authentication Utility
/// 
/// Generates HTTP Basic Auth headers for VLC Web Interface.
/// VLC expects empty username with password only.

class BasicAuth {
  /// Generates Base64 encoded Basic Auth header value
  /// 
  /// VLC Web Interface uses:
  /// - Username: empty string
  /// - Password: user-provided password
  /// 
  /// Returns the full header value including "Basic " prefix
  static String generateHeader(String password) {
    // VLC expects empty username, so format is ":password"
    final credentials = ':$password';
    final bytes = utf8.encode(credentials);
    final base64Credentials = base64Encode(bytes);
    return 'Basic $base64Credentials';
  }
  
  /// Creates a Map with the Authorization header
  /// Ready to use with http package
  static Map<String, String> getHeaders(String password) {
    return {
      'Authorization': generateHeader(password),
    };
  }
}
