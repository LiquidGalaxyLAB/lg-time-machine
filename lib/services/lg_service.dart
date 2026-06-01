import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LGService extends ChangeNotifier {
  static final LGService instance = LGService._init();
  LGService._init();

  SSHClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  int get screens => _screens;
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
      
      await _client!.authenticated;
      
      _isConnected = true;
      notifyListeners();
      
      // Ensure directories exist
      await execute('mkdir -p /var/www/html/logos');
      await execute('mkdir -p /var/www/html/kml');
      
      return true;
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> reconnect() async {
    if (_host == null || _port == null || _username == null || _password == null) return;
    try {
      final socket = await SSHSocket.connect(_host!, _port!, timeout: const Duration(seconds: 5));
      _client = SSHClient(
        socket,
        username: _username!,
        onPasswordRequest: () => _password,
      );
      await _client!.authenticated;
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    notifyListeners();
    try {
      _client?.close();
    } catch (e) {
      // Ignore errors during close
    }
    _client = null;
  }

  Future<String?> execute(String command) async {
    if (_client == null || _client?.isClosed == true) {
      await reconnect();
    }
    if (!_isConnected || _client == null) return null;
    try {
      final session = await _client!.execute(command);
      return await utf8.decodeStream(session.stdout);
    } catch (e) {
      _isConnected = false; // Mark as disconnected if execution fails due to connection
      notifyListeners();
      return null;
    }
  }

  Future<void> sendKML(String kml) async {
    await execute("cat <<'EOF' > /var/www/html/kmls.kml\n$kml\nEOF");
    await _setKmlTxt();
  }

  Future<void> sendTimeKML(String kml) async {
    await execute("cat <<'EOF' > /var/www/html/time.kml\n$kml\nEOF");
    await _setTimeKmlTxt();
  }

  Future<void> sendLogoKML(String kml) async {
    await execute("mkdir -p /var/www/html/kml");
    await execute("cat <<'EOF' > /var/www/html/kml/slave_1.kml\n$kml\nEOF");
  }

  Future<void> uploadAssets() async {
    if (!_isConnected || _client == null) return;

    final assets = [
      {'path': 'assets/images/KMLs/Logo/KMLs_Logo.png', 'name': 'KMLs_Logo.png'},
    ];

    try {
      await execute('mkdir -p /var/www/html/logos');
      final sftp = await _client!.sftp();
      
      for (var asset in assets) {
        try {
          final byteData = await rootBundle.load(asset['path']!);
          final bytes = byteData.buffer.asUint8List();
          final file = await sftp.open('/var/www/html/logos/${asset['name']}', 
            mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate);
          await file.write(Stream.value(bytes));
          await file.close();
        } catch (e) {
          print('Error uploading ${asset['name']}: $e');
        }
      }
    } catch (e) {
      print('SFTP Error: $e');
    }
  }

  Future<void> _setKmlTxt() async {
    final kmlContent = "echo 'http://lg1:81/kmls.kml' > /var/www/html/kmls.txt";
    await execute(kmlContent);
  }

  Future<void> _setTimeKmlTxt() async {
    final kmlContent = "echo 'http://lg1:81/time.kml' > /var/www/html/kmls.txt";
    await execute(kmlContent);
  }

  Future<void> sendQuery(String query) async {
    await execute('echo "$query" > /tmp/query.txt');
  }

  bool _orbitPlaying = false;
  bool get orbitPlaying => _orbitPlaying;
  Timer? _orbitTimer;
  String? _lastOrbitPosition;

  String orbitLookAtLinear(
    double latitude,
    double longitude,
    double zoom,
    double tilt,
    double bearing,
  ) {
    final lookAt =
        '<gx:duration>0.3</gx:duration><gx:flyToMode>smooth</gx:flyToMode><LookAt>'
        '<longitude>$longitude</longitude><latitude>$latitude</latitude>'
        '<range>$zoom</range><tilt>$tilt</tilt>'
        '<heading>$bearing</heading>'
        '<altitudeMode>relativeToGround</altitudeMode></LookAt>';

    _lastOrbitPosition = lookAt;
    return lookAt;
  }

  Future<void> flyToOrbit(
    String context,
    double latitude,
    double longitude,
    double zoom,
    double tilt,
    double bearing,
  ) async {
    try {
      final String lookAt = orbitLookAtLinear(
        latitude,
        longitude,
        zoom,
        tilt,
        bearing,
      );
      await sendQuery('flytoview=$lookAt');
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (error) {
      print('Error in flyToOrbit: $error');
    }
  }

  Future<bool> orbitPlay(
    double latitude,
    double longitude,
    double zoom,
    double tilt, {
    double initialBearing = 0,
  }) async {
    if (_orbitPlaying) {
      return false;
    }

    if (!_isConnected) {
      print('Cannot start orbit: LG not connected');
      return false;
    }

    _orbitPlaying = true;
    notifyListeners();

    try {
      const int steps = 60;
      const int stepDuration = 400; // ms
      // Calculate starting step from initial bearing
      int currentStep = (initialBearing * steps / 360).floor();
      bool isMoving = false;

      _orbitTimer = Timer.periodic(const Duration(milliseconds: stepDuration), (
        timer,
      ) async {
        if (!_orbitPlaying) {
          timer.cancel();
          return;
        }

        if (isMoving) {
          return;
        }

        try {
          isMoving = true;
          double bearing = (currentStep * (360 / steps)) % 360;
          await flyToOrbit(
            'Orbit',
            latitude,
            longitude,
            zoom,
            tilt,
            bearing,
          ).timeout(const Duration(milliseconds: 380));
          currentStep++;
          isMoving = false;
        } catch (e) {
          isMoving = false;
        }
      });

      return true;
    } catch (e) {
      _orbitPlaying = false;
      notifyListeners();
      print('Error during orbit: $e');
      return false;
    }
  }

  Future<void> orbitStop() async {
    _orbitTimer?.cancel();
    _orbitTimer = null;
    _orbitPlaying = false;
    notifyListeners();

    try {
      await sendQuery('exittour=true');

      if (_lastOrbitPosition != null) {
        await sendQuery(
          'flytoview=$_lastOrbitPosition',
        );
      }
    } catch (e) {
      print('Error stopping orbit: $e');
    }
  }

  Future<void> clearKML() async {
    await execute("echo '' > /var/www/html/kmls.kml");
  }

  Future<void> clearLogos() async {
    int rigs = _screens - 1;
    if (rigs < 1) rigs = 1;
    String blank = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
  </Document>
</kml>''';
    await execute("mkdir -p /var/www/html/kml");
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
