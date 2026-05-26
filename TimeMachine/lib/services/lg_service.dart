import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:convert';

class LGService {
  static final LGService instance = LGService._init();
  LGService._init();

  SSHClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port, timeout: const Duration(seconds: 5));
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Test connection by running a simple command
      await _client?.run('ls');
      
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    _client?.close();
    await _client?.done;
    _client = null;
    _isConnected = false;
  }

  Future<String?> execute(String command) async {
    if (!_isConnected || _client == null) return null;
    try {
      final session = await _client!.execute(command);
      final result = await utf8.decodeStream(session.stdout);
      return result;
    } catch (e) {
      return null;
    }
  }
}
