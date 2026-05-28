import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class LGService {
  static final LGService instance = LGService._init();
  LGService._init();

  SSHClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  String? _host;
  int? _port;

  String? _password;
  int _screens = 3;
  String? _username;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    int screens = 3,
  }) async {
    _host = host;
    _port = port;
    _username = username;
    _password = password;
    _screens = screens;
    try {
      final socket = await SSHSocket.connect(host, port, timeout: const Duration(seconds: 5));
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      _isConnected = true;
      
      // Ensure directories exist
      await execute('mkdir -p /var/www/html/logos');
      await execute('mkdir -p /var/www/html/kml');
      
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    try {
      _client?.close();
    } catch (e) {
      // Ignore errors during close
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
    await execute("cat <<'EOF' > /var/www/html/kmls.kml\n$kml\nEOF");
    await _setKmlTxt();
  }

  Future<void> sendLogoKML(String kml) async {
    int rigs = (_screens / 2).floor() + 2;
    await execute("cat <<'EOF' > /var/www/html/kml/slave_$rigs.kml\n$kml\nEOF");
  }

  Future<void> uploadAssets() async {
    final assets = [
      'bg_box.png',
      'LiquidGalaxyTimeMachine_Logo.png',
      'LiquidGalaxy_Logo.png',
      'GoogleSummerOfCode_Logo.png',
      'LaboratorisTIC_Logo.png',
    ];

    await execute('mkdir -p /var/www/html/logos');

    for (var asset in assets) {
      try {
        final byteData = await rootBundle.load('assets/images/KMLs/Logo/$asset');
        final bytes = byteData.buffer.asUint8List();
        final session = await _client!.sftp();
        final file = await session.open('/var/www/html/logos/$asset', mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
        await file.write(Stream.value(bytes));
        await file.close();
      } catch (e) {
        print('Error uploading $asset: $e');
      }
    }
  }

  Future<void> _setKmlTxt() async {
    final kmlContent = "echo 'http://lg1:81/kmls.kml' > /var/www/html/kmls.txt";
    await execute(kmlContent);
  }

  Future<void> sendQuery(String query) async {
    await execute("echo '$query' > /tmp/query.txt");
  }

  Future<void> clearKML() async {
    await execute("echo '' > /var/www/html/kmls.kml");
  }

  Future<void> clearLogos() async {
    int rigs = (_screens / 2).floor() + 2;
    String blank = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
  </Document>
</kml>''';
    await execute("cat <<'EOF' > /var/www/html/kml/slave_$rigs.kml\n$blank\nEOF");
  }

  Future<void> relaunch() async {
    if (_password == null || _username == null) return;
    
    for (var i = _screens; i >= 1; i--) {
      final relaunchCommand = """RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo $_password | sudo -S service \\\${SERVICE} start
else
  echo $_password | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p $_password ssh -x -t lg@lg$i "\$RELAUNCH_CMD\"""";
      
      await execute('"/home/$_username/bin/lg-relaunch" > /home/$_username/log.txt');
      await execute(relaunchCommand);
    }
  }

  Future<void> shutdown() async {
    if (_password == null) return;
    for (var i = _screens; i >= 1; i--) {
      await execute(
          'sshpass -p $_password ssh -t lg$i "echo $_password | sudo -S poweroff"');
    }
  }

  Future<void> reboot() async {
    if (_password == null) return;
    for (var i = _screens; i >= 1; i--) {
      await execute(
          'sshpass -p $_password ssh -t lg$i "echo $_password | sudo -S reboot"');
    }
  }

  Future<void> setRefresh() async {
    if (_password == null) return;
    try {
      const search = '<href>##LG_PHPIFACE##kml\\\\/slave_{{slave}}.kml<\\\\/href>';
      const replace =
          '<href>##LG_PHPIFACE##kml\\\\/slave_{{slave}}.kml<\\\\/href><refreshMode>onInterval<\\\\/refreshMode><refreshInterval>2<\\\\/refreshInterval>';
      
      for (var i = 2; i <= _screens; i++) {
        final clearCmd = 'echo $_password | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml'
            .replaceAll('{{slave}}', i.toString());
        final cmd = 'echo $_password | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml'
            .replaceAll('{{slave}}', i.toString());
            
        String queryClear = 'sshpass -p $_password ssh -t lg$i \'$clearCmd\'';
        String querySet = 'sshpass -p $_password ssh -t lg$i \'$cmd\'';

        await execute(queryClear);
        await execute(querySet);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> resetRefresh() async {
    if (_password == null) return;
    try {
      const search =
          '<href>##LG_PHPIFACE##kml\\\\/slave_{{slave}}.kml<\\\\/href><refreshMode>onInterval<\\\\/refreshMode><refreshInterval>2<\\\\/refreshInterval>';
      const replace = '<href>##LG_PHPIFACE##kml\\\\/slave_{{slave}}.kml<\\\\/href>';

      for (var i = 2; i <= _screens; i++) {
        final cmd = 'echo $_password | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml'
            .replaceAll('{{slave}}', i.toString());
        String query = 'sshpass -p $_password ssh -t lg$i \'$cmd\'';

        await execute(query);
      }
    } catch (e) {
      print(e);
    }
  }
}
