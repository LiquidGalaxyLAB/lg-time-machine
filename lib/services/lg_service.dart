import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:convert';
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
  String? get host => _host;
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
      debugPrint('LGService: Intentando conectar a $host:$port...');
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      debugPrint('LGService: Autenticando usuario $username...');
      await _client!.authenticated.timeout(const Duration(seconds: 15));

      _isConnected = true;
      notifyListeners();
      debugPrint('LGService: Conexión establecida con éxito');

      // Limpiar y asegurar directorios con permisos totales
      await execute('echo $_password | sudo -S mkdir -p /var/www/html/logos');
      await execute(
        'echo $_password | sudo -S chmod -R 777 /var/www/html/logos',
      );
      await execute(
        'echo $_password | sudo -S rm -f /var/www/html/logos/statistics.png',
      ); // Eliminar basura previa
      await execute('echo $_password | sudo -S mkdir -p /var/www/html/kml');
      await execute('echo $_password | sudo -S chmod -R 777 /var/www/html/kml');

      // Configurar refrescos automáticos en todas las pantallas
      await setRefresh();

      return true;
    } catch (e) {
      debugPrint('LGService: Error de conexión: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> reconnect() async {
    if (_host == null ||
        _port == null ||
        _username == null ||
        _password == null)
      return;
    try {
      final socket = await SSHSocket.connect(
        _host!,
        _port!,
        timeout: const Duration(seconds: 10),
      );
      _client = SSHClient(
        socket,
        username: _username!,
        onPasswordRequest: () => _password,
      );
      await _client!.authenticated.timeout(const Duration(seconds: 15));
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
      final result = await utf8.decodeStream(session.stdout);
      return result;
    } catch (e) {
      debugPrint('LGService: Execution error for "$command": $e');
      // Only disconnect if it's a connection-related error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        _isConnected = false;
        notifyListeners();
      }
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

  Future<void> sendSlaveKML(int slaveNo, String kml) async {
    await execute('echo $_password | sudo -S mkdir -p /var/www/html/kml');
    await execute('echo $_password | sudo -S chmod -R 777 /var/www/html/kml');
    await execute(
      "cat <<'EOF' > /var/www/html/kml/slave_$slaveNo.kml\n$kml\nEOF",
    );
  }

  Future<void> sendLogoKML(String kml) async {
    // En tu configuración de 5 pantallas, LG4 es el objetivo (slave_4).
    // En uno de 3 pantallas, LG2 es el objetivo (slave_2).
    int slaveNo = _screens == 5 ? 4 : 2;
    await sendSlaveKML(slaveNo, kml);
  }

  Future<void> uploadAssets() async {
    if (!_isConnected || _client == null || _password == null) return;

    final assets = [
      {'path': 'assets/images/KMLs/Logo/Logos.png', 'name': 'Logos.png'},
    ];

    try {
      // 1. Crear el directorio y dar permisos totales usando sudo
      await execute('echo $_password | sudo -S mkdir -p /var/www/html/logos');
      await execute(
        'echo $_password | sudo -S chmod -R 777 /var/www/html/logos',
      );

      final sftp = await _client!.sftp();

      for (var asset in assets) {
        try {
          final byteData = await rootBundle.load(asset['path']!);
          final bytes = byteData.buffer.asUint8List();
          final remotePath = '/var/www/html/logos/${asset['name']}';

          final file = await sftp.open(
            remotePath,
            mode:
                SftpFileOpenMode.create |
                SftpFileOpenMode.write |
                SftpFileOpenMode.truncate,
          );
          await file.write(Stream.value(bytes));
          await file.close();
          debugPrint('LGService: cargado ${asset['name']} en $remotePath');
        } catch (e) {
          debugPrint('LGService: Error subiendo ${asset['name']}: $e');
        }
      }
    } catch (e) {
      debugPrint('LGService: Error de SFTP: $e');
    }
  }

  Future<String?> uploadPOIImage(String assetPath, {String? customName}) async {
    if (!_isConnected || _client == null || _password == null) return null;

    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // Detectamos la extensión real del archivo (jpg o png)
      final extension = assetPath.split('.').last.toLowerCase();
      final fileName = customName != null
          ? '$customName.$extension'
          : 'statistics.$extension';
      final remotePath = '/var/www/html/logos/$fileName';

      // Eliminamos versiones anteriores del mismo nombre para evitar conflictos de extensión
      if (customName == null) {
        await execute(
          'echo $_password | sudo -S rm -f /var/www/html/logos/statistics.jpg',
        );
        await execute(
          'echo $_password | sudo -S rm -f /var/www/html/logos/statistics.png',
        );
      } else {
        await execute(
          'echo $_password | sudo -S rm -f /var/www/html/logos/$customName.jpg',
        );
        await execute(
          'echo $_password | sudo -S rm -f /var/www/html/logos/$customName.png',
        );
      }

      final sftp = await _client!.sftp();
      final file = await sftp.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await file.write(Stream.value(bytes));
      await file.close();

      debugPrint('LGService: cargado POI image $fileName en $remotePath');
      return fileName;
    } catch (e) {
      debugPrint('LGService: Error subiendo POI image: $e');
      return null;
    }
  }

  Future<void> openBrowser(int screenNo, String url) async {
    final user = _username ?? 'lg';
    final chromeArgs =
        "--no-first-run --no-default-browser-check --kiosk --incognito "
        "--disable-infobars --disable-session-crashed-bubble "
        "--user-data-dir=/tmp/chrome$screenNo --no-sandbox --disable-gpu "
        "--test-type --disable-features=Translate --no-errdialogs";

    final command =
        "export DISPLAY=:0; "
        "export XAUTHORITY=/home/$user/.Xauthority; "
        "(google-chrome $chromeArgs '$url' || "
        "google-chrome-stable $chromeArgs '$url' || "
        "chromium-browser $chromeArgs '$url' || "
        "chromium $chromeArgs '$url') "
        "> /dev/null 2>&1 &";

    debugPrint('LGService: Opening browser on screen $screenNo with URL: $url');
    if (screenNo == 1) {
      await execute(command);
    } else {
      await execute(
        "sshpass -p '$_password' ssh -n -o StrictHostKeyChecking=no $user@lg$screenNo \"$command\"",
      );
    }
  }

  Future<void> stopBrowser(int screenNo) async {
    final user = _username ?? 'lg';
    final command = "pkill -f /tmp/chrome$screenNo || true";
    debugPrint('LGService: Stopping browser on screen $screenNo');
    if (screenNo == 1) {
      await execute(command);
    } else {
      await execute(
        "sshpass -p '$_password' ssh -n -o StrictHostKeyChecking=no $user@lg$screenNo \"$command\"",
      );
    }
  }

  Future<void> createStatisticsHTML(String imageUrl) async {
    final bool isThreeScreen = _screens == 3;
    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    margin: 0;
    padding: 0;
    overflow: hidden;
    background-color: black;
    width: 100vw;
    height: 100vh;
  }
  .container {
    width: 300vw;
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    position: absolute;
    top: 0;
    left: 0;
  }
  img.bg {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
  .logo-overlay {
    position: fixed;
    bottom: 40px;
    right: 40px;
    width: 250px;
    height: auto;
    z-index: 1000;
    display: ${isThreeScreen ? 'block' : 'none'};
  }
</style>
</head>
<body>
  <div class="container" id="container">
    <img class="bg" src="$imageUrl">
  </div>
  
  <img src="http://lg1:81/logos/Logos.png" class="logo-overlay">

  <script>
    const urlParams = new URLSearchParams(window.location.search);
    const screen = urlParams.get('screen');
    const container = document.getElementById('container');

    if (screen === 'left') {
      container.style.left = '0vw';
    }
    if (screen === 'center') {
      container.style.left = '-100vw';
    }
    if (screen === 'right') {
      container.style.left = '-200vw';
    }
  </script>
</body>
</html>
''';
    await execute(
      "cat <<'EOF' > /var/www/html/statistics.html\n$htmlContent\nEOF",
    );
  }

  Future<void> createComparisonHTML(String pastUrl, String presentUrl) async {
    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    margin: 0;
    padding: 0;
    overflow: hidden;
    background-color: black;
    width: 100vw;
    height: 100vh;
  }
  .container {
    width: 200vw;
    height: 100vh;
    display: flex;
    position: absolute;
    top: 0;
    left: 0;
  }
  img {
    width: 200vw;
    height: 100vh;
    object-fit: cover;
  }
</style>
</head>
<body>
  <div class="container" id="container">
    <img id="main-img" src="">
  </div>
  
  <script>
    const urlParams = new URLSearchParams(window.location.search);
    const side = urlParams.get('side'); // 'left' or 'right'
    const mode = urlParams.get('mode'); // 'past' or 'present'
    
    const img = document.getElementById('main-img');
    const container = document.getElementById('container');

    if (mode === 'past') {
      img.src = '$pastUrl';
    } else {
      img.src = '$presentUrl';
    }

    if (side === 'right') {
      container.style.left = '-100vw';
    } else {
      container.style.left = '0vw';
    }
  </script>
</body>
</html>
''';
    await execute(
      "cat <<'EOF' > /var/www/html/comparison.html\n$htmlContent\nEOF",
    );
  }

  Future<void> clearStatistics() async {
    await stopBrowser(1);
    await stopBrowser(2);
    if (_screens == 5) {
      await stopBrowser(4);
      await stopBrowser(5);
    }
    await clearSlaveKML(3);
  }

  Future<void> clearComparison() async {
    await stopBrowser(1);
    await stopBrowser(2);
    await stopBrowser(4);
    await stopBrowser(5);
    await clearSlaveKML(3);
  }

  Future<void> clearSlaveKML(int slaveNo) async {
    String blank = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document></Document>
</kml>''';
    await execute(
      "cat <<'EOF' > /var/www/html/kml/slave_$slaveNo.kml\n$blank\nEOF",
    );
  }

  Future<void> _setKmlTxt() async {
    final version = DateTime.now().millisecondsSinceEpoch;
    final kmlContent =
        "echo 'http://lg1:81/kmls.kml?v=$version' > /var/www/html/kmls.txt";
    await execute(kmlContent);
  }

  Future<void> _setTimeKmlTxt() async {
    final version = DateTime.now().millisecondsSinceEpoch;
    final kmlContent =
        "echo 'http://lg1:81/time.kml?v=$version' > /var/www/html/kmls.txt";
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
        await sendQuery('flytoview=$_lastOrbitPosition');
      }
    } catch (e) {
      print('Error stopping orbit: $e');
    }
  }

  Future<void> clearKML() async {
    await execute("echo '' > /var/www/html/kmls.kml");
    await _setKmlTxt();
  }

  Future<void> clearTime() async {
    await execute("echo '' > /var/www/html/time.kml");
    await _setTimeKmlTxt();
  }

  Future<void> clearLogos() async {
    String blank = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document></Document>
</kml>''';
    await execute("mkdir -p /var/www/html/kml");
    // Limpiamos todos los esclavos posibles para asegurar que no queden logos residuales
    for (var i = 1; i <= _screens; i++) {
      await execute(
        "cat <<'EOF' > /var/www/html/kml/slave_$i.kml\n$blank\nEOF",
      );
    }
  }

  Future<void> relaunch() async {
    if (_password == null || _username == null) return;
    final user = _username!;

    await setRefresh();

    for (var i = _screens; i >= 1; i--) {
      final relaunchCommand =
          """RELAUNCH_CMD="\\
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
" && sshpass -p $_password ssh -x -t $user@lg$i "\$RELAUNCH_CMD\"""";

      if (i == 1) {
        await execute('"/home/$user/bin/lg-relaunch" > /home/$user/log.txt');
      } else {
        await execute(
          'sshpass -p $_password ssh -t lg$i "\"/home/$user/bin/lg-relaunch\" > /home/$user/log.txt"',
        );
      }
      await execute(relaunchCommand);
    }
  }

  Future<void> shutdown() async {
    if (_password == null) return;
    final user = _username ?? 'lg';
    for (var i = _screens; i >= 1; i--) {
      await execute(
        'sshpass -p $_password ssh -t $user@lg$i "echo $_password | sudo -S poweroff"',
      );
    }
  }

  Future<void> reboot() async {
    if (_password == null) return;
    final user = _username ?? 'lg';
    for (var i = _screens; i >= 1; i--) {
      await execute(
        'sshpass -p $_password ssh -t $user@lg$i "echo $_password | sudo -S reboot"',
      );
    }
  }

  Future<void> setRefresh() async {
    if (_password == null) return;
    try {
      for (var i = 1; i <= _screens; i++) {
        // Rutas directas para asegurar la configuración
        final paths = [
          '/home/lg/earth/kml/myplaces.kml',
          '/home/lg/earth/kml/slave/myplaces.kml',
          '/home/lg/.googleearth/instance-1/myplaces.kml',
        ];

        final host = i == 1 ? 'localhost' : 'lg1';
        final globalUrl = 'http://$host:81/kmls.txt';
        final slaveUrl = 'http://$host:81/kml/slave_$i.kml';

        for (var path in paths) {
          String script =
              """
            if [ -f $path ]; then
              # Eliminar entradas previas para evitar duplicidad o basura
              sed -i '/slave_$i.kml/d' $path
              sed -i '/kmls.txt/d' $path
              # Insertar nuevos NetworkLinks antes del cierre del Documento
              sed -i '/<\\/Document>/i <NetworkLink><name>global_$i</name><Link><href>$globalUrl</href><refreshMode>onInterval</refreshMode><refreshInterval>2</refreshInterval></Link></NetworkLink>' $path
              sed -i '/<\\/Document>/i <NetworkLink><name>slave_$i</name><Link><href>$slaveUrl</href><refreshMode>onChange</refreshMode></Link></NetworkLink>' $path
            fi
          """;

          String execCmd = "echo '$_password' | sudo -S bash -c \"$script\"";
          if (i == 1) {
            await execute(execCmd);
          } else {
            await execute('sshpass -p $_password ssh -t lg$i "$execCmd"');
          }
        }
      }
      debugPrint('LGService: Refresco configurado e inyectado correctamente.');
    } catch (e) {
      debugPrint('LGService: Error crítico en setRefresh: $e');
    }
  }

  Future<void> resetRefresh() async {
    if (_password == null) return;
    try {
      for (var i = 1; i <= _screens; i++) {
        String path = i == 1
            ? '~/earth/kml/myplaces.kml'
            : '~/earth/kml/slave/myplaces.kml';
        // Eliminamos las etiquetas de refresco
        final cmd =
            "echo '$_password' | sudo -S sed -i 's@<refreshMode>onInterval</refreshMode><refreshInterval>2</refreshInterval>@@g' $path";
        await execute('sshpass -p $_password ssh -t lg$i "$cmd"');
      }
    } catch (e) {
      debugPrint('LGService: Error al resetear refresco: $e');
    }
  }
}
