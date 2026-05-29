import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class LanguageManager {
  static final LanguageManager instance = LanguageManager._init();
  LanguageManager._init();

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'connect': 'Connect',
      'timeline': 'Timeline',
      'settings': 'Settings',
      'search_countries': 'Search countries...',
      'lg_user': 'LG USER',
      'lg_password': 'LG PASSWORD',
      'ip': 'IP',
      'lg_port': 'LG PORT',
      'screens': 'NUMBER OF SCREENS',
      'connect_button': 'CONNECT',
      'disconnect_button': 'DISCONNECT',
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'about_us': 'ABOUT US',
      'help': 'HELP',
      'connection': 'CONNECTION',
      'preferences': 'PREFERENCES',
      'language': 'LANGUAGE',
      'lg_tools': 'LG TOOLS',
      'relaunch': 'RELAUNCH',
      'shutdown': 'SHUTDOWN',
      'clean_kmls': 'CLEAN KMLS',
      'clean_logos': 'CLEAN LOGOS',
      'reboot_lg': 'REBOOT LG',
      'set_refresh': 'SET SLAVES REFRESH',
      'reset_refresh': 'RESET SLAVES REFRESH',
      'show_hide_logos': 'SHOW/HIDE LOGOS',
      'past': 'PAST',
      'present': 'PRESENT',
      'future': 'FUTURE',
      'travel_lg': 'TRAVEL IN LIQUID GALAXY',
      'confirm_title': 'CONFIRMATION',
      'confirm_message': 'Are you sure you want to',
      'yes': 'YES',
      'no': 'NO',
      'generate_future': 'GENERATE FUTURE ESTIMATION IMAGE',
      'regenerate_future': 'REGENERATE FUTURE ESTIMATION',
      'ai_generated': 'AI GENERATED',
      'estimation_of': 'Estimation of',
      'generating_future': 'Generating future estimation image...',
      'future_success': 'Future estimation image generated successfully!',
    },
    'es': {
      'connect': 'Conectar',
      'timeline': 'Línea de tiempo',
      'settings': 'Ajustes',
      'search_countries': 'Buscar países...',
      'lg_user': 'USUARIO LG',
      'lg_password': 'PASSWORD LG',
      'ip': 'IP',
      'lg_port': 'PUERTO LG',
      'screens': 'NÚMERO DE PANTALLAS',
      'connect_button': 'CONECTAR',
      'connected': 'Conectado',
      'disconnected': 'Desconectado',
      'about_us': 'SOBRE NOSOTROS',
      'help': 'AYUDA',
      'connection': 'CONEXIÓN',
      'preferences': 'PREFERENCIAS',
      'language': 'IDIOMA',
      'lg_tools': 'HERRAMIENTAS LG',
      'relaunch': 'REINICIAR APP',
      'shutdown': 'APAGAR',
      'clean_kmls': 'LIMPIAR KMLS',
      'clean_logos': 'LIMPIAR LOGOS',
      'reboot_lg': 'REINICIAR LG',
      'set_refresh': 'ACTIVAR REFRESCO',
      'reset_refresh': 'DESACTIVAR REFRESCO',
      'show_hide_logos': 'MOSTRAR/OCULTAR LOGOS',
      'past': 'PASADO',
      'present': 'PRESENTE',
      'future': 'FUTURO',
      'travel_lg': 'VIAJAR EN LIQUID GALAXY',
      'confirm_title': 'CONFIRMACIÓN',
      'confirm_message': '¿Estás seguro de que quieres',
      'yes': 'SÍ',
      'no': 'NO',
      'generate_future': 'GENERAR IMAGEN DE ESTIMACIÓN FUTURA',
      'regenerate_future': 'REGENERAR ESTIMACIÓN FUTURA',
      'ai_generated': 'GENERADO POR IA',
      'estimation_of': 'Estimación de',
      'generating_future': 'Generando imagen de estimación futura...',
      'future_success': '¡Imagen de estimación futura generada con éxito!',
    },
    'ca': {
      'connect': 'Connectar',
      'timeline': 'Línia de temps',
      'settings': 'Configuració',
      'search_countries': 'Cercar països...',
      'lg_user': 'USUARI LG',
      'lg_password': 'CONTRASENYA LG',
      'ip': 'IP',
      'lg_port': 'PORT LG',
      'screens': 'NOMBRE DE PANTALLES',
      'connect_button': 'CONNECTAR',
      'connected': 'Connectat',
      'disconnected': 'Desconnectat',
      'about_us': 'SOBRE NOSALTRES',
      'help': 'AJUDA',
      'connection': 'CONNEXIÓ',
      'preferences': 'PREFERÈNCIES',
      'language': 'IDIOMA',
      'lg_tools': 'EINES LG',
      'relaunch': 'REINICIAR APP',
      'shutdown': 'APAGAR',
      'clean_kmls': 'NETEJAR KMLS',
      'clean_logos': 'NETEJAR LOGOS',
      'reboot_lg': 'REINICIAR LG',
      'set_refresh': 'ACTIVAR REFRESCO',
      'reset_refresh': 'DESACTIVAR REFRESCO',
      'show_hide_logos': 'MOSTRAR/OCULTAR LOGOS',
      'past': 'PASSAT',
      'present': 'PRESENT',
      'future': 'FUTUR',
      'travel_lg': 'VIATJAR A LIQUID GALAXY',
      'confirm_title': 'CONFIRMACIÓ',
      'confirm_message': 'Estàs segur que vols',
      'yes': 'SÍ',
      'no': 'NO',
      'generate_future': 'GENERAR IMATGE D\'ESTIMACIÓ FUTURA',
      'regenerate_future': 'REGENERAR ESTIMACIÓ FUTURA',
      'ai_generated': 'GENERAT PER IA',
      'estimation_of': 'Estimació de',
      'generating_future': 'Generant imatge d\'estimació futura...',
      'future_success': 'Imatge d\'estimació futura generada correctament!',
    },
  };

  Future<void> init() async {
    final savedLang = await DatabaseHelper.instance.getSetting('language');
    if (savedLang != null) {
      _currentLanguage = savedLang;
      languageNotifier.value = savedLang;
    }
  }

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  Future<void> changeLanguage(String langCode) async {
    if (_translations.containsKey(langCode)) {
      _currentLanguage = langCode;
      languageNotifier.value = langCode;
      await DatabaseHelper.instance.saveSetting('language', langCode);
    }
  }
}
