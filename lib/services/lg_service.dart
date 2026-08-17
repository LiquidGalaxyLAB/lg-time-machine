import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LGService extends ChangeNotifier {
  static final LGService instance = LGService._init();

  // LG3 es el slave reservado para el balloon HTML/KML.
  // En la configuración de 3 pantallas es la pantalla derecha; en la
  // configuración de 5 pantallas se mantiene independiente de la comparación.
  static const int _balloonSlave = 3;
  LGService._init();

  SSHClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _lastKml;
  String? _lastTimeKml;
  final Map<int, String> _lastSlaveKml = {};
  String? _poiBoundaryKml;
  String? _balloonKml;
  double _poiBoundaryLatitude = 0;
  double _poiBoundaryLongitude = 0;
  int get screens => _screens;
  String? _host;
  String? get host => _host;
  int? _port;

  String? _password;
  int _screens = 3;
  String? _username;
  bool _isPreCaching = false;
  Future<void>? _reconnectFuture;

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

      // Limpiar y asegurar directorios con una sola llamada combinada
      await execute(
        'echo $_password | sudo -S bash -c "mkdir -p /var/www/html/logos /var/www/html/kml && chmod -R 777 /var/www/html && rm -f /var/www/html/logos/statistics.png"',
      );

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
    if (_reconnectFuture != null) return _reconnectFuture;
    if (_host == null ||
        _port == null ||
        _username == null ||
        _password == null)
      return;

    _reconnectFuture = _reconnectInternal();
    try {
      await _reconnectFuture;
    } finally {
      _reconnectFuture = null;
    }
  }

  Future<void> _reconnectInternal() async {
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
      final result = await utf8.decodeStream(session.stdout).timeout(const Duration(seconds: 15));
      await session.done.timeout(const Duration(seconds: 2));
      return result;
    } catch (e) {
      debugPrint('LGService: Execution error for "$command": $e');
      // Reconnect on connection-related errors or timeouts
      if (e is TimeoutException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed') ||
          e.toString().contains('SSHChannelOpenError')) {
        _isConnected = false;
        notifyListeners();
      }
      return null;
    }
  }

  Future<void> sendKML(String kml) async {
    if (_lastKml == kml) return;
    _lastKml = kml;
    await execute("cat <<'EOF' > /var/www/html/kmls.kml\n$kml\nEOF");
    await _setKmlTxt();
  }

  String generatePOIBoundaryKML({
    required double latitude,
    required double longitude,
    double sizeMeters = 200.0,
    double heightMeters = 15.0,
  }) {
    final halfSize = sizeMeters / 2.0;
    const metersPerDegree = 111320.0;

    final latOffset = halfSize / metersPerDegree;
    final cosLat = math.cos(latitude * math.pi / 180.0).abs();
    final lonOffset =
        halfSize / (metersPerDegree * math.max(cosLat, 0.01));

    final north = latitude + latOffset;
    final south = latitude - latOffset;
    final east = longitude + lonOffset;
    final west = longitude - lonOffset;

    // KML uses AABBGGRR. 99 = 60% opacity, 0000ff = blue.
    const blueFill = '990000ff';
    const blueLine = 'ff0000ff';

    String wall(
        double lon1,
        double lat1,
        double lon2,
        double lat2,
        ) {
      return '''
    <Placemark>
      <name>POI Boundary Wall</name>
      <Style>
        <PolyStyle>
          <color>$blueFill</color>
          <fill>1</fill>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>$blueLine</color>
          <width>4</width>
        </LineStyle>
      </Style>
      <Polygon>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon1,$lat1,0
              $lon2,$lat2,0
              $lon2,$lat2,$heightMeters
              $lon1,$lat1,$heightMeters
              $lon1,$lat1,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''';
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>POI 3D Boundary</name>
${wall(west, north, east, north)}
${wall(east, north, east, south)}
${wall(east, south, west, south)}
${wall(west, south, west, north)}
  </Document>
</kml>''';
  }

  Future<String?> sendPOIBoundaryKML({
    required double latitude,
    required double longitude,
    double sizeMeters = 200.0,
    double heightMeters = 15.0,
  }) async {
    if (!_isConnected) {
      debugPrint('LGService: Cannot send POI boundary: not connected');
      return 'not_connected';
    }

    try {
      final kml = generatePOIBoundaryKML(
        latitude: latitude,
        longitude: longitude,
        sizeMeters: sizeMeters,
        heightMeters: heightMeters,
      );

      _poiBoundaryKml = kml;
      _poiBoundaryLatitude = latitude;
      _poiBoundaryLongitude = longitude;

      debugPrint(
        'LGService: Writing 3D POI boundary into slave KMLs '
            '(lat=$latitude, lon=$longitude, size=${sizeMeters}m, height=${heightMeters}m)',
      );

      // La barrera utiliza el mismo canal slave_X.kml.
      // IMPORTANTE: slave 3 NO se excluye. En él conviven la barrera 3D
      // y el balloon. El balloon se añade al final del mismo Document KML,
      // por lo que el 3D queda como elemento de fondo y no lo sobrescribe.
      for (int slaveNo = 1; slaveNo <= _screens; slaveNo++) {
        await _writeSlaveKML(slaveNo);
      }

      // Forzamos un nuevo wrapper/URL para que Google Earth recargue
      // inmediatamente cada slave. LG3 conserva 3D + balloon.
      for (int slaveNo = 1; slaveNo <= _screens; slaveNo++) {
        await _refreshSlaveKML(slaveNo);
      }

      debugPrint('LGService: 3D POI boundary sent through slave KML path');
      return null;
    } catch (e) {
      debugPrint('LGService: Error sending POI boundary: $e');
      return 'boundary_error';
    }
  }

  Future<void> clearPOIBoundary() async {
    _poiBoundaryKml = null;

    // Quitamos únicamente la geometría 3D. El balloon de LG3
    // permanece y se vuelve a escribir en el mismo KML.
    for (int slaveNo = 1; slaveNo <= _screens; slaveNo++) {
      await _writeSlaveKML(slaveNo);
    }

    debugPrint(
      'LGService: 3D POI boundary cleared; balloon slave 3 preserved.',
    );
  }

  Future<void> sendTimeKML(String kml) async {
    if (_lastTimeKml == kml) return;
    _lastTimeKml = kml;
    await execute("cat <<'EOF' > /var/www/html/time.kml\n$kml\nEOF");
    await _setTimeKmlTxt();
  }

  Future<void> sendSlaveKML(int slaveNo, String kml) async {
    if (_lastSlaveKml[slaveNo] == kml && _poiBoundaryKml == null) {
      return;
    }

    _lastSlaveKml[slaveNo] = kml;
    await _writeSlaveKML(slaveNo);
  }

  /// El balloon de estadísticas/comparación siempre vive en LG3.
  ///
  /// LG3 se mantiene independiente de los browsers usados por la
  /// comparación. El KML de LG3 contiene simultáneamente la barrera 3D
  /// y el balloon, por lo que ninguno de los dos sobrescribe al otro.
  Future<void> sendBalloonKML(String kml) async {
    if (_screens < _balloonSlave) {
      debugPrint(
        'LGService: No hay LG3 disponible para el balloon '
            '(_screens=$_screens).',
      );
      return;
    }

    _balloonKml = kml;

    // No usamos un return cuando el contenido es idéntico. El fichero
    // slave_3.kml puede haber sido actualizado por otra operación y
    // necesitamos garantizar que el NetworkLink se vuelva a refrescar.
    await _writeSlaveKML(_balloonSlave);
    await _refreshSlaveKML(_balloonSlave);

    debugPrint(
      'LGService: Balloon enviado/refrescado en LG3 junto con la barrera 3D.',
    );
  }

  /// Elimina únicamente el balloon. La barrera 3D, si existe, permanece.
  Future<void> clearBalloonKML() async {
    if (_screens < _balloonSlave) return;

    _balloonKml = null;
    await _writeSlaveKML(_balloonSlave);
    await _refreshSlaveKML(_balloonSlave);

    debugPrint(
      'LGService: Balloon de LG3 eliminado; barrera 3D conservada.',
    );
  }

  Future<void> _writeSlaveKML(int slaveNo) async {
    final baseKml = _lastSlaveKml[slaveNo] ?? '';
    final boundary = _poiBoundaryKml ?? '';
    final balloon = slaveNo == _balloonSlave ? (_balloonKml ?? '') : '';

    final kml = _composeSlaveKML(
      baseKml: baseKml,
      boundaryKml: boundary,
      balloonKml: balloon,
    );

    await execute(
      "cat <<'EOF' > /var/www/html/kml/slave_$slaveNo.kml\n$kml\nEOF",
    );
    await _setSlaveKmlTxt(slaveNo);
  }

  String _composeSlaveKML({
    required String baseKml,
    required String boundaryKml,
    required String balloonKml,
  }) {
    final baseBody = _extractKmlDocumentBody(baseKml);
    final boundaryBody = _extractKmlDocumentBody(boundaryKml);
    final balloonBody = _extractKmlDocumentBody(balloonKml);

    if (baseBody.isEmpty && boundaryBody.isEmpty && balloonBody.isEmpty) {
      return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document></Document>
</kml>''';
    }

    // ORDEN IMPORTANTE:
    // base -> barrera 3D -> balloon.
    // El balloon queda en el mismo Document y no reemplaza la geometría 3D.
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
$baseBody
$boundaryBody
$balloonBody
  </Document>
</kml>''';
  }

  String _extractKmlDocumentBody(String kml) {
    final documentStart = kml.indexOf('<Document');
    if (documentStart == -1) return '';

    final openEnd = kml.indexOf('>', documentStart);
    if (openEnd == -1) return '';

    final closeStart = kml.lastIndexOf('</Document>');
    if (closeStart == -1 || closeStart <= openEnd) return '';

    return kml.substring(openEnd + 1, closeStart).trim();
  }

  Future<void> _setSlaveKmlTxt(int slaveNo) async {
    final version = DateTime.now().millisecondsSinceEpoch;
    final kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <NetworkLink>
      <Link>
        <href>http://lg1:81/kml/slave_$slaveNo.kml?v=$version</href>
        <refreshMode>onInterval</refreshMode>
        <refreshInterval>1</refreshInterval>
      </Link>
    </NetworkLink>
  </Document>
</kml>''';
    await execute("cat <<'EOF' > /var/www/html/kml/slave_$slaveNo.txt\n$kmlContent\nEOF");
  }

  Future<void> _refreshSlaveKML(int slaveNo) async {
    // Reescribe el wrapper completo en vez de depender de sed. Esto evita
    // problemas de caché y garantiza un nuevo query-string en cada cambio.
    await _setSlaveKmlTxt(slaveNo);
  }

  Future<void> sendLogoKML(String kml) async {
    int slaveNo = _screens == 5 ? 4 : 2;
    await sendSlaveKML(slaveNo, kml);
    // sendSlaveKML already composes the current boundary, if one exists.
  }

  Future<void> uploadLogos() async {
    if (!_isConnected || _client == null || _password == null) return;

    try {
      final sftp = await _client!.sftp();
      await _uploadSftpFile(
        sftp,
        'assets/images/KMLs/Logo/Logos.png',
        '/var/www/html/logos/Logos.png',
      );
    } catch (e) {
      debugPrint('LGService: Error uploading logos: $e');
    }
  }

  Future<void> preCachePOIImages(List<String> poiAssetPaths) async {
    if (!_isConnected || _client == null || _password == null || _isPreCaching) return;

    _isPreCaching = true;
    final currentClient = _client;

    try {
      final sftp = await currentClient!.sftp();
      for (var assetPath in poiAssetPaths) {
        // Verify if we are still connected and using the same client
        if (!_isConnected || _client != currentClient || _client?.isClosed == true) break;

        final fileName = assetPath.split('/').last;
        final remotePath = '/var/www/html/logos/$fileName';

        try {
          // Check if file already exists to avoid redundant uploads and potential conflicts
          await sftp.stat(remotePath);
          continue;
        } catch (_) {
          // File does not exist, proceed with upload
        }

        await _uploadSftpFile(sftp, assetPath, remotePath);
        // Small delay to allow other SSH commands to multiplex through if needed
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint('LGService: Error in background pre-caching: $e');
    } finally {
      _isPreCaching = false;
    }
  }

  Future<void> _uploadSftpFile(dynamic sftp, String localPath, String remotePath) async {
    try {
      final byteData = await rootBundle.load(localPath);
      final bytes = byteData.buffer.asUint8List();
      final file = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await file.write(Stream.value(bytes));
      await file.close();
      debugPrint('LGService: Uploaded $remotePath');
    } catch (e) {
      debugPrint('LGService: Failed to upload $localPath: $e');
    }
  }

  Future<String?> uploadPOIImage(String assetPath, {String? customName, bool isExternal = false}) async {
    if (!_isConnected || _client == null || _password == null) return null;

    try {
      Uint8List bytes;
      if (isExternal) {
        final file = File(assetPath);
        bytes = await file.readAsBytes();
      } else {
        final byteData = await rootBundle.load(assetPath);
        bytes = byteData.buffer.asUint8List();
      }

      // Detectamos la extensión real del archivo (jpg o png)
      final extension = assetPath.split('.').last.toLowerCase();
      final fileName = customName != null
          ? '$customName.$extension'
          : 'statistics.$extension';
      final remotePath = '/var/www/html/logos/$fileName';

      // Combined RM command to save SSH channels and prevent SSHChannelOpenError
      final String rmBase = customName ?? 'statistics';
      await execute(
        'rm -f /var/www/html/logos/$rmBase.jpg /var/www/html/logos/$rmBase.png',
      );

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
        "sshpass -p '$_password' ssh -n -o ConnectTimeout=5 -o StrictHostKeyChecking=no $user@lg$screenNo \"$command\"",
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
        "sshpass -p '$_password' ssh -n -o ConnectTimeout=5 -o StrictHostKeyChecking=no $user@lg$screenNo \"$command\"",
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
    await Future.wait([
      stopBrowser(1),
      stopBrowser(2),
      if (_screens == 5) ...[
        stopBrowser(4),
        stopBrowser(5),
      ],
      clearBalloonKML(),
    ]);
  }

  Future<void> clearComparison() async {
    await Future.wait([
      stopBrowser(1),
      stopBrowser(2),
      stopBrowser(4),
      stopBrowser(5),
      clearBalloonKML(),
    ]);
  }

  Future<void> clearSlaveKML(int slaveNo) async {
    _lastSlaveKml.remove(slaveNo);
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
    final kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <NetworkLink>
      <Link>
        <href>http://lg1:81/kmls.kml?v=$version</href>
      </Link>
    </NetworkLink>
  </Document>
</kml>''';
    await execute("cat <<'EOF' > /var/www/html/kmls.txt\n$kmlContent\nEOF");
  }

  Future<void> _setTimeKmlTxt() async {
    final version = DateTime.now().millisecondsSinceEpoch;
    final kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <NetworkLink>
      <Link>
        <href>http://lg1:81/time.kml?v=$version</href>
      </Link>
    </NetworkLink>
  </Document>
</kml>''';
    await execute("cat <<'EOF' > /var/www/html/time.txt\n$kmlContent\nEOF");
  }

  Future<void> sendQuery(String query) async {
    await execute('echo "$query" > /tmp/query.txt');
  }

  bool _orbitPlaying = false;
  bool get orbitPlaying => _orbitPlaying;

  Future<void> stopMovement() async {
    await sendQuery('exittour=true');
  }
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
      // First, fly to the initial position to ensure we are at the coordinates
      final String initialLookAt = orbitLookAtLinear(
        latitude,
        longitude,
        zoom,
        tilt,
        initialBearing,
      ).replaceAll(
        '<gx:duration>0.3</gx:duration>',
        '<gx:duration>4.0</gx:duration>',
      );

      await sendQuery('flytoview=$initialLookAt');
      // Wait for the flyto to finish before starting the orbit rotation
      await Future.delayed(const Duration(milliseconds: 4000));

      if (!_orbitPlaying) return true;

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
    _lastKml = null;
    _lastTimeKml = null;
    _lastSlaveKml.clear();
    _poiBoundaryKml = null;
    _balloonKml = null;

    if (_orbitPlaying) {
      orbitStop();
    }

    // Combined command to stop movement and clear KML files for efficiency
    int logoSlave = _screens == 5 ? 4 : 2;
    String clearSlavesCmd = "";
    for (int i = 1; i <= _screens; i++) {
      if (i != logoSlave) {
        clearSlavesCmd += "echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document></Document></kml>' > /var/www/html/kml/slave_$i.kml; ";
      }
    }

    await execute(
        "echo 'exittour=true' > /tmp/query.txt; "
            "echo '' > /var/www/html/kmls.kml; "
            "echo '' > /var/www/html/time.kml; "
            "$clearSlavesCmd"
    );

    // Refresh the TXT wrappers
    await _setKmlTxt();
    await _setTimeKmlTxt();
    for (int i = 1; i <= _screens; i++) {
      if (i != logoSlave) {
        await _setSlaveKmlTxt(i);
      }
    }

    // Stop browsers on all screens
    for (int i = 1; i <= _screens; i++) {
      stopBrowser(i);
    }
  }

  Future<void> clearTime() async {
    _lastTimeKml = null;
    await execute("echo '' > /var/www/html/time.kml");
    await _setTimeKmlTxt();
  }

  Future<void> clearLogos() async {
    int logoSlave = _screens == 5 ? 4 : 2;
    await clearSlaveKML(logoSlave);
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
    final user = _username ?? 'lg';
    try {
      final paths = [
        '/home/$user/earth/kml/myplaces.kml',
        '/home/$user/earth/kml/slave/myplaces.kml',
        '/home/$user/.googleearth/instance-1/myplaces.kml',
      ];

      List<Future> futures = [];
      for (var i = 1; i <= _screens; i++) {
        final host = i == 1 ? 'localhost' : 'lg1';
        final globalUrl = 'http://$host:81/kmls.txt';
        final timeUrl = 'http://$host:81/time.txt';
        final slaveUrl = 'http://$host:81/kml/slave_$i.txt';

        String script = "for path in ${paths.join(' ')}; do "
            "if [ -f \$path ]; then "
            "sed -i '/global_[0-9]/d' \$path; "
            "sed -i '/time_[0-9]/d' \$path; "
            "sed -i '/slave_[0-9]/d' \$path; "
            "sed -i '/kmls.txt/d' \$path; "
            "sed -i '/time.txt/d' \$path; "
            "sed -i '/slave_.*\\.txt/d' \$path; "
            "sed -i '/slave_.*\\.kml/d' \$path; "
            "sed -i '/<\\/Document>/i <NetworkLink><name>global_$i</name><Link><href>$globalUrl</href><refreshMode>onInterval</refreshMode><refreshInterval>2</refreshInterval></Link></NetworkLink>' \$path; "
            "sed -i '/<\\/Document>/i <NetworkLink><name>time_$i</name><Link><href>$timeUrl</href><refreshMode>onInterval</refreshMode><refreshInterval>2</refreshInterval></Link></NetworkLink>' \$path; "
            "sed -i '/<\\/Document>/i <NetworkLink><name>slave_$i</name><Link><href>$slaveUrl</href><refreshMode>onInterval</refreshMode><refreshInterval>2</refreshInterval></Link></NetworkLink>' \$path; "
            "fi; done";

        String execCmd = "echo '$_password' | sudo -S bash -c \"\$script\"";
        if (i == 1) {
          futures.add(execute(execCmd));
        } else {
          futures.add(execute(
            "sshpass -p '$_password' ssh -n -o StrictHostKeyChecking=no $user@lg$i \"\$execCmd\"",
          ));
        }
      }
      await Future.wait(futures);
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
        // Eliminamos las etiquetas de refresco y posibles restos de configuraciones anteriores
        final cmd =
            "echo '$_password' | sudo -S sed -i '/global_$i/d; /time_$i/d; /slave_$i/d; /kmls.txt/d; /time.txt/d; /slave_.*\\.kml/d; /slave_.*\\.txt/d' $path; "
            "echo '$_password' | sudo -S sed -i 's@<refreshMode>onChange</refreshMode>@@g' $path; "
            "echo '$_password' | sudo -S sed -i 's@<refreshMode>onInterval</refreshMode><refreshInterval>2</refreshInterval>@@g' $path";
        await execute('sshpass -p $_password ssh -t lg$i "$cmd"');
      }
    } catch (e) {
      debugPrint('LGService: Error al resetear refresco: $e');
    }
  }
}

