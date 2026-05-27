import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

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
    int screens = 3,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port, timeout: const Duration(seconds: 5));
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Test connection
      await _client?.execute('ls');
      
      _isConnected = true;
      
      // Automatically attempt to upload logo images to the Liquid Galaxy
      await _uploadLogos();
      
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<void> _uploadLogos() async {
    try {
      final sftp = await _client?.sftp();
      if (sftp == null) return;

      // Ensure the logos directory exists
      await execute('mkdir -p /var/www/html/logos');

      final logoFiles = [
        'LiquidGalaxyTimeMachine_Logo.png',
        'LiquidGalaxy_Logo.png',
        'GoogleSummerOfCode_Logo.png',
        'LaboratorisTIC_Logo.png',
        'bg_box.png', // Assuming this image is provided for the curvy background
      ];

      for (var fileName in logoFiles) {
        try {
          final ByteData data = await rootBundle.load('assets/images/KMLs/Logo/$fileName');
          final Uint8List bytes = data.buffer.asUint8List();
          final file = await sftp.open('/var/www/html/logos/$fileName', 
              mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
          await file.writeBytes(bytes);
          await file.close();
        } catch (e) {
          // If a file is missing in assets, we skip it
          continue;
        }
      }
    } catch (e) {
      // SFTP might not be enabled or another error occurred
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    try {
      _client?.close();
    } catch (e) {
      // Ignore errors during close to avoid SSHSocketError crashes
    }
    _client = null;
  }

  Future<String?> execute(String command) async {
    if (!_isConnected || _client == null) return null;
    try {
      final session = await _client!.execute(command);
      return await utf8.decodeStream(session.stdout);
    } catch (e) {
      return null;
    }
  }

  Future<void> sendKML(String kml) async {
    // Use single quotes for EOF to prevent shell expansion of KML content
    await execute("cat <<'EOF' > /var/www/html/kmls.kml\n$kml\nEOF");
    await _setKmlTxt();
  }

  Future<void> sendLogoKML(String kml) async {
    await execute("cat <<'EOF' > /var/www/html/logos.kml\n$kml\nEOF");
    await _setKmlTxt();
  }

  Future<void> _setKmlTxt() async {
    // Load both logos and content KMLs
    await execute("echo -e 'http://lg1:81/logos.kml\nhttp://lg1:81/kmls.kml' > /var/www/html/kmls.txt");
  }

  Future<void> sendQuery(String query) async {
    await execute("echo '$query' > /tmp/query.txt");
  }

  Future<void> clearKML() async {
    await execute("echo '' > /var/www/html/kmls.kml");
  }

  Future<void> clearLogos() async {
    await execute("echo '' > /var/www/html/logos.kml");
  }

  Future<void> relaunch() async {
    await execute('lg-relaunch');
  }

  Future<void> shutdown() async {
    await execute('lg-poweroff');
  }

  Future<void> reboot() async {
    await execute('lg-reboot');
  }
}
