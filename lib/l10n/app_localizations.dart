import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('es', ''),
    Locale('en', ''),
  ];

  // Traducciones básicas
  String get home => locale.languageCode == 'en' ? 'Home' : 'Inicio';
  String get newTab => locale.languageCode == 'en' ? 'New' : 'Nueva';
  String get settings => locale.languageCode == 'en' ? 'Settings' : 'Ajustes';
  String get createAlarm => locale.languageCode == 'en' ? 'Create Alarm' : 'Crear Alarma';
  String get editAlarm => locale.languageCode == 'en' ? 'Edit Alarm' : 'Editar Alarma';
  String get alarmName => locale.languageCode == 'en' ? 'Alarm name' : 'Nombre de la alarma';
  String get location => locale.languageCode == 'en' ? 'Location' : 'Ubicación';
  String get activationRange => locale.languageCode == 'en' ? 'Activation range (m)' : 'Rango de activación (m)';
  String get requiredField => locale.languageCode == 'en' ? 'Required field' : 'Campo requerido';
  String get selectLocation => locale.languageCode == 'en' ? 'Select a location' : 'Selecciona una ubicación';
  String get saveChanges => locale.languageCode == 'en' ? 'Save Changes' : 'Guardar Cambios';
  String get createAlarmButton => locale.languageCode == 'en' ? 'Create Alarm' : 'Crear Alarma';
  String get deleteAlarm => locale.languageCode == 'en' ? 'Delete Alarm' : 'Eliminar Alarma';
  String get deleteAlarmConfirm => locale.languageCode == 'en' ? 'Are you sure you want to delete this alarm?' : '¿Estás seguro que quieres eliminar esta alarma?';
  String get cancel => locale.languageCode == 'en' ? 'Cancel' : 'Cancelar';
  String get delete => locale.languageCode == 'en' ? 'Delete' : 'Eliminar';
  String get noAlarmsSaved => locale.languageCode == 'en' ? 'No saved alarms' : 'No hay alarmas guardadas';
  String get createFirstAlarm => locale.languageCode == 'en' ? 'Tap the + button to create your first alarm' : 'Toca el botón + para crear tu primera alarma';
  String get language => locale.languageCode == 'en' ? 'Language' : 'Idioma';
  String get selectAppLanguage => locale.languageCode == 'en' ? 'Select application language' : 'Seleccionar idioma de la aplicación';
  String get spanish => 'Español';
  String get english => 'English';
  String get searchLocation => locale.languageCode == 'en' ? 'Search for a location' : 'Busca una ubicación';
  
  // Traducciones para ajustes
  String get notificationsAndSound => locale.languageCode == 'en' ? 'Notifications and Sound' : 'Notificaciones y Sonido';
  String get notifications => locale.languageCode == 'en' ? 'Notifications' : 'Notificaciones';
  String get receiveAlarmNotifications => locale.languageCode == 'en' ? 'Receive alarm notifications' : 'Recibir notificaciones de alarmas';
  String get sound => locale.languageCode == 'en' ? 'Sound' : 'Sonido';
  String get playAlarmSound => locale.languageCode == 'en' ? 'Play alarm sound' : 'Reproducir sonido de alarma';
  String get vibration => locale.languageCode == 'en' ? 'Vibration' : 'Vibración';
  String get vibrateOnAlarm => locale.languageCode == 'en' ? 'Vibrate when alarm activates' : 'Vibrar al activar alarma';
  String get locationAndMaps => locale.languageCode == 'en' ? 'Location and Maps' : 'Ubicación y Mapas';
  String get locationServices => locale.languageCode == 'en' ? 'Location services' : 'Servicios de ubicación';
  String get allowLocationAccess => locale.languageCode == 'en' ? 'Allow location access' : 'Permitir acceso a la ubicación';
  String get defaultRadius => locale.languageCode == 'en' ? 'Default radius' : 'Radio por defecto';
  String get defaultDistanceForNewAlarms => locale.languageCode == 'en' ? 'Default distance for new alarms' : 'Distancia predeterminada para nuevas alarmas';
  String get meters => locale.languageCode == 'en' ? 'meters' : 'metros';
  String get personalization => locale.languageCode == 'en' ? 'Personalization' : 'Personalización';
  String get theme => locale.languageCode == 'en' ? 'Theme' : 'Tema';
  String get appearance => locale.languageCode == 'en' ? 'Application appearance' : 'Apariencia de la aplicación';
  String get light => locale.languageCode == 'en' ? 'Light' : 'Claro';
  String get dark => locale.languageCode == 'en' ? 'Dark' : 'Oscuro';
  String get system => locale.languageCode == 'en' ? 'System' : 'Sistema';
  String get performance => locale.languageCode == 'en' ? 'Performance' : 'Rendimiento';
  String get autoStart => locale.languageCode == 'en' ? 'Auto start' : 'Inicio automático';
  String get startAppOnDeviceBoot => locale.languageCode == 'en' ? 'Start application on device boot' : 'Iniciar aplicación al encender el dispositivo';
  String get batteryOptimization => locale.languageCode == 'en' ? 'Battery optimization' : 'Optimización de batería';
  String get optimizeBatteryUsage => locale.languageCode == 'en' ? 'Optimize battery usage' : 'Optimizar uso de batería';
  String get dataCache => locale.languageCode == 'en' ? 'Data cache' : 'Caché de datos';
  String get saveDataForOfflineUse => locale.languageCode == 'en' ? 'Save data for offline use' : 'Guardar datos para uso offline';
  String get permissionsAndData => locale.languageCode == 'en' ? 'Permissions and Data' : 'Permisos y Datos';
  String get managePermissions => locale.languageCode == 'en' ? 'Manage permissions' : 'Gestionar permisos';
  String get configureAppPermissions => locale.languageCode == 'en' ? 'Configure application permissions' : 'Configurar permisos de la aplicación';
  String get clearCache => locale.languageCode == 'en' ? 'Clear cache' : 'Limpiar caché';
  String get deleteTemporaryData => locale.languageCode == 'en' ? 'Delete temporary data' : 'Eliminar datos temporales';
  String get deleteAllData => locale.languageCode == 'en' ? 'Delete all data' : 'Eliminar todos los datos';
  String get deleteAlarmsAndSettings => locale.languageCode == 'en' ? 'Delete alarms and settings' : 'Borrar alarmas y configuraciones';
  String get information => locale.languageCode == 'en' ? 'Information' : 'Información';
  String get version => locale.languageCode == 'en' ? 'Version' : 'Versión';
  String get privacyPolicy => locale.languageCode == 'en' ? 'Privacy policy' : 'Política de privacidad';
  String get howWeProtectYourData => locale.languageCode == 'en' ? 'How we protect your data' : 'Cómo protegemos tus datos';
  String get helpAndSupport => locale.languageCode == 'en' ? 'Help and support' : 'Ayuda y soporte';
  String get getHelpWithApp => locale.languageCode == 'en' ? 'Get help with the application' : 'Obtener ayuda con la aplicación';
  String get comingSoon => locale.languageCode == 'en' ? 'Coming soon' : 'Próximamente disponible';
  String get cacheClearedSuccessfully => locale.languageCode == 'en' ? 'Cache cleared successfully' : 'Caché limpiado correctamente';
  String get allDataDeleted => locale.languageCode == 'en' ? 'All data has been deleted' : 'Todos los datos han sido eliminados';
  String get permissionsRequested => locale.languageCode == 'en' ? 'Permissions requested' : 'Permisos solicitados';
  String get deleteAllDataConfirm => locale.languageCode == 'en' ? 'This action will delete all alarms and settings. Are you sure you want to continue?' : 'Esta acción eliminará todas las alarmas y configuraciones. ¿Estás seguro de que quieres continuar?';
  
  // Traducciones para permisos
  String get locationPermissionRequired => locale.languageCode == 'en' ? 'Location permissions required' : 'Permisos de ubicación requeridos';
  String get locationPermissionMessage => locale.languageCode == 'en' ? 'We need access to your location to work properly' : 'Necesitamos acceso a tu ubicación para funcionar correctamente';
  String get grantPermissions => locale.languageCode == 'en' ? 'Grant permissions' : 'Conceder permisos';
  
  // Traducciones para alarmas
  String get alarmDeleted => locale.languageCode == 'en' ? 'Alarm deleted' : 'Alarma eliminada';
  String get undo => locale.languageCode == 'en' ? 'UNDO' : 'DESHACER';
  
  // Traducciones para clima
  String get lowCloudiness => locale.languageCode == 'en' ? 'Low cloudiness' : 'Poca nubosidad';
  String get myLocation => locale.languageCode == 'en' ? 'My location' : 'Mi ubicación';
  
  // Traducciones para alarmas
  String get address => locale.languageCode == 'en' ? 'Address' : 'Dirección';
  String get range => locale.languageCode == 'en' ? 'Range' : 'Rango';
  String get unknown => locale.languageCode == 'en' ? 'Unknown' : 'Desconocida';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}