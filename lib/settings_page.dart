import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tfg_definitivo2/database_helper.dart';
import 'package:tfg_definitivo2/theme_provider.dart';
import 'package:tfg_definitivo2/l10n/app_localizations.dart';
import 'package:tfg_definitivo2/alarm_sounds.dart';
import 'package:logger/logger.dart';
import 'package:tfg_definitivo2/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _defaultRadius = 100.0;
  String _selectedLanguage = 'es';
  String _selectedTheme = 'light';
  bool _autoStartEnabled = false;
  bool _batteryOptimizationEnabled = false;
  bool _cacheEnabled = true;
  String _selectedAlarmSound = 'default';
  final Logger _logger = Logger();
  
  // Variables para reproducción de sonidos
  final AudioPlayer _previewPlayer = AudioPlayer();
  final GlobalAudioManager _audioManager = GlobalAudioManager();
  String? _currentlyPlayingSound;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Registrar el player de vista previa
    _audioManager.registerPlayer(_previewPlayer);
    
    _loadSettings();
  }

  @override
  void dispose() {
    // Desregistrar el player antes de disponerlo
    _audioManager.unregisterPlayer(_previewPlayer);
    _previewPlayer.dispose();
    super.dispose();
  }
  
  // Función para detener el player de vista previa
  Future<void> stopPreviewPlayer() async {
    try {
      await _previewPlayer.stop();
      await _previewPlayer.setReleaseMode(ReleaseMode.release);
      _logger.d('✅ PLAYER DE VISTA PREVIA DETENIDO');
    } catch (e) {
      _logger.d('⚠️ ERROR DETENIENDO PLAYER DE VISTA PREVIA: $e');
    }
  }

  List<Map<String, String>> _getLanguageItems() {
    return [
      {'value': 'es', 'label': AppLocalizations.of(context).spanish},
      {'value': 'en', 'label': AppLocalizations.of(context).english},
    ];
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationEnabled = prefs.getBool('location_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _defaultRadius = prefs.getDouble('default_radius') ?? 100.0;
      _selectedLanguage = prefs.getString('selected_language') ?? 'es';
      _selectedTheme = themeProvider.currentThemeString;
      _autoStartEnabled = prefs.getBool('auto_start_enabled') ?? false;
      _batteryOptimizationEnabled = prefs.getBool('battery_optimization_enabled') ?? false;
      _cacheEnabled = prefs.getBool('cache_enabled') ?? true;
      _selectedAlarmSound = prefs.getString('selected_alarm_sound') ?? 'default';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('weather_') || key.startsWith('route_')) {
        await prefs.remove(key);
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cacheClearedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteAllData),
        content: Text(AppLocalizations.of(context).deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteLocalDatabase();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).allDataDeleted),
            backgroundColor: Colors.red,
          ),
        );
        _loadSettings();
      }
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.location.request();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).permissionsRequested),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _playSoundPreview(String soundId) async {
    try {
      // Si ya está reproduciendo el mismo sonido, detenerlo
      if (_currentlyPlayingSound == soundId && _isPlaying) {
        await _stopSoundPreview();
        return;
      }

      // Detener cualquier sonido que esté reproduciéndose
      await _stopSoundPreview();

      final sound = AlarmSoundManager.getSoundById(soundId);
      if (sound != null) {
        // Actualizar estado ANTES de reproducir
        setState(() {
          _currentlyPlayingSound = soundId;
          _isPlaying = true;
        });
        
        // Reproducir en bucle para la vista previa (para que pueda durar más tiempo)
        await _previewPlayer.setReleaseMode(ReleaseMode.loop);
        await _previewPlayer.play(AssetSource(sound.assetPath));
        
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSound = null;
        });
      }
    }
  }

  Future<void> _stopSoundPreview() async {
    try {
      await _previewPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSound = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSound = null;
        });
      }
    }
  }

  Future<void> _playSoundPreviewInModal(String soundId, StateSetter setModalState) async {
    try {
      // Si ya está reproduciendo el mismo sonido, detenerlo
      if (_currentlyPlayingSound == soundId && _isPlaying) {
        await _stopSoundPreviewInModal(setModalState);
        return;
      }

      // Detener cualquier sonido que esté reproduciéndose
      await _stopSoundPreviewInModal(setModalState);

      final sound = AlarmSoundManager.getSoundById(soundId);
      if (sound != null) {
        // Actualizar estado ANTES de reproducir
        _currentlyPlayingSound = soundId;
        _isPlaying = true;
        setModalState(() {}); // Forzar reconstrucción del modal
        
        // Reproducir en bucle para la vista previa
        await _previewPlayer.setReleaseMode(ReleaseMode.loop);
        await _previewPlayer.play(AssetSource(sound.assetPath));
        
      }
    } catch (e) {
      _isPlaying = false;
      _currentlyPlayingSound = null;
      setModalState(() {});
    }
  }

  Future<void> _stopSoundPreviewInModal(StateSetter setModalState) async {
    try {
      await _previewPlayer.stop();
      _isPlaying = false;
      _currentlyPlayingSound = null;
      setModalState(() {}); // Forzar reconstrucción del modal
    } catch (e) {
      _isPlaying = false;
      _currentlyPlayingSound = null;
      setModalState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).settings,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(AppLocalizations.of(context).notificationsAndSound),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: CupertinoIcons.bell,
                title: AppLocalizations.of(context).notifications,
                subtitle: AppLocalizations.of(context).receiveAlarmNotifications,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSetting('notifications_enabled', value);
                },
              ),
              _buildSwitchTile(
                icon: CupertinoIcons.speaker_2,
                title: AppLocalizations.of(context).sound,
                subtitle: AppLocalizations.of(context).playAlarmSound,
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  _saveSetting('sound_enabled', value);
                },
              ),
              _buildSwitchTile(
                icon: CupertinoIcons.waveform,
                title: AppLocalizations.of(context).vibration,
                subtitle: AppLocalizations.of(context).vibrateOnAlarm,
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSetting('vibration_enabled', value);
                },
              ),
              _buildSoundSelectorTile(),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context).locationAndMaps),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: CupertinoIcons.location,
                title: AppLocalizations.of(context).locationServices,
                subtitle: AppLocalizations.of(context).allowLocationAccess,
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() => _locationEnabled = value);
                  _saveSetting('location_enabled', value);
                },
              ),
              _buildSliderTile(
                icon: CupertinoIcons.circle_grid_hex,
                title: AppLocalizations.of(context).defaultRadius,
                subtitle: AppLocalizations.of(context).defaultDistanceForNewAlarms,
                value: _defaultRadius,
                min: 50,
                max: 500,
                divisions: 9,
                onChanged: (value) {
                  setState(() => _defaultRadius = value);
                  _saveSetting('default_radius', value);
                },
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context).personalization),
            _buildSettingsCard([
              _buildDropdownTile(
                icon: CupertinoIcons.globe,
                title: AppLocalizations.of(context).language,
                subtitle: AppLocalizations.of(context).selectAppLanguage,
                value: _selectedLanguage,
                items: _getLanguageItems(),
                onChanged: (value) {
                  setState(() => _selectedLanguage = value);
                  _saveSetting('selected_language', value);
                  // Cambiar idioma en tiempo real
                  Provider.of<ThemeProvider>(context, listen: false).setLanguage(value);
                },
              ),
              _buildDropdownTile(
                icon: CupertinoIcons.paintbrush,
                title: AppLocalizations.of(context).theme,
                subtitle: AppLocalizations.of(context).appearance,
                value: _selectedTheme,
                items: [
                  {'value': 'light', 'label': AppLocalizations.of(context).light},
                  {'value': 'dark', 'label': AppLocalizations.of(context).dark},
                  {'value': 'system', 'label': AppLocalizations.of(context).system},
                ],
                onChanged: (value) async {
                  setState(() => _selectedTheme = value);
                  _saveSetting('selected_theme', value);
                  
                  // Cambiar tema usando el provider
                  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                  await themeProvider.setTheme(value);
                },
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context).performance),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: CupertinoIcons.play_circle,
                title: AppLocalizations.of(context).autoStart,
                subtitle: AppLocalizations.of(context).startAppOnDeviceBoot,
                value: _autoStartEnabled,
                onChanged: (value) {
                  setState(() => _autoStartEnabled = value);
                  _saveSetting('auto_start_enabled', value);
                },
              ),
              _buildSwitchTile(
                icon: CupertinoIcons.battery_charging,
                title: AppLocalizations.of(context).batteryOptimization,
                subtitle: AppLocalizations.of(context).optimizeBatteryUsage,
                value: _batteryOptimizationEnabled,
                onChanged: (value) {
                  setState(() => _batteryOptimizationEnabled = value);
                  _saveSetting('battery_optimization_enabled', value);
                },
              ),
              _buildSwitchTile(
                icon: CupertinoIcons.cloud_download,
                title: AppLocalizations.of(context).dataCache,
                subtitle: AppLocalizations.of(context).saveDataForOfflineUse,
                value: _cacheEnabled,
                onChanged: (value) {
                  setState(() => _cacheEnabled = value);
                  _saveSetting('cache_enabled', value);
                },
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context).permissionsAndData),
            _buildSettingsCard([
              _buildActionTile(
                icon: CupertinoIcons.checkmark_shield,
                title: AppLocalizations.of(context).managePermissions,
                subtitle: AppLocalizations.of(context).configureAppPermissions,
                onTap: _requestPermissions,
              ),
              _buildActionTile(
                icon: CupertinoIcons.trash,
                title: AppLocalizations.of(context).clearCache,
                subtitle: AppLocalizations.of(context).deleteTemporaryData,
                onTap: _clearCache,
              ),
              _buildActionTile(
                icon: CupertinoIcons.delete_solid,
                title: AppLocalizations.of(context).deleteAllData,
                subtitle: AppLocalizations.of(context).deleteAlarmsAndSettings,
                onTap: _clearAllData,
                isDestructive: true,
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context).information),
            _buildSettingsCard([
              _buildInfoTile(
                icon: CupertinoIcons.info_circle,
                title: AppLocalizations.of(context).version,
                subtitle: '1.0.0',
              ),
              _buildActionTile(
                icon: CupertinoIcons.doc_text,
                title: AppLocalizations.of(context).privacyPolicy,
                subtitle: AppLocalizations.of(context).howWeProtectYourData,
                onTap: () {
                  // TODO: Implementar política de privacidad
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
                  );
                },
              ),
              _buildActionTile(
                icon: CupertinoIcons.question_circle,
                title: AppLocalizations.of(context).helpAndSupport,
                subtitle: AppLocalizations.of(context).getHelpWithApp,
                onTap: () {
                  // TODO: Implementar ayuda
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
                  );
                },
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: children.map((child) {
          final isLast = child == children.last;
          return Column(
            children: [
              child,
              if (!isLast)
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerTheme.color,
                  indent: 60,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blue.withOpacity(0.2)
              : Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blue[300]
              : Colors.blue[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.green.withOpacity(0.2)
              : Colors.green[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.green[300]
              : Colors.green[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toInt()} ${AppLocalizations.of(context).meters}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: SizedBox(
        width: 100,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.purple.withOpacity(0.2)
              : Colors.purple[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.purple[300]
              : Colors.purple[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 14,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Text(item['label']!),
          );
        }).toList(),
        underline: Container(),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.red.withOpacity(0.2)
                  : Colors.red[50])
              : (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.orange[50]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.red[300]
                  : Colors.red[600])
              : (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.orange[300]
                  : Colors.orange[600]),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDestructive 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.red[300]
                  : Colors.red[600])
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[500]
            : Colors.grey[400],
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.withOpacity(0.2)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[400]
              : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSoundSelectorTile() {
    final currentSound = AlarmSoundManager.getSoundById(_selectedAlarmSound) ?? 
                        AlarmSoundManager.getDefaultSound();
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.orange.withOpacity(0.2)
              : Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          CupertinoIcons.music_note_2,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.orange[300]
              : Colors.orange[600],
          size: 20,
        ),
      ),
      title: Text(
        'Sonido de Alarma',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      subtitle: Text(
        currentSound.description,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentSound.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[500]
                : Colors.grey[400],
            size: 16,
          ),
        ],
      ),
      onTap: _showSoundSelector,
    );
  }

  void _showSoundSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Seleccionar Sonido de Alarma',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      if (_isPlaying) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...AlarmSoundManager.availableSounds.map((sound) {
              final isSelected = sound.id == _selectedAlarmSound;
              final isPlaying = _currentlyPlayingSound == sound.id && _isPlaying;
              
              // Debug: imprimir estado para cada sonido
              
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? CupertinoIcons.checkmark : CupertinoIcons.music_note_2,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
                title: Text(
                  sound.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                subtitle: Text(
                  sound.description,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de reproducción con animación
                    GestureDetector(
                      onTap: () => _playSoundPreviewInModal(sound.id, setModalState),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isPlaying 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isPlaying ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              isPlaying ? CupertinoIcons.stop_fill : CupertinoIcons.play_fill,
                              color: isPlaying 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[600],
                              size: 16,
                            ),
                            if (isPlaying)
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Container(
                                    width: 36 + (value * 8),
                                    height: 36 + (value * 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3 * (1 - value)),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                },
                                onEnd: () {
                                  // Reiniciar la animación
                                  if (_currentlyPlayingSound == sound.id && _isPlaying) {
                                    setState(() {});
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() => _selectedAlarmSound = sound.id);
                  _saveSetting('selected_alarm_sound', sound.id);
                  _logger.i('🔧 Sonido de alarma seleccionado: ${sound.name} (ID: ${sound.id})');
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      );
        },
      ),
    ).then((_) {
      // Detener el sonido cuando se cierre el modal
      _stopSoundPreview();
    });
  }
}
