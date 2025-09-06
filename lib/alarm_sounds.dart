import 'package:flutter/material.dart';

class AlarmSound {
  final String id;
  final String name;
  final String assetPath;
  final String description;

  const AlarmSound({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.description,
  });
}

class AlarmSoundManager {
  static const List<AlarmSound> _availableSounds = [
    AlarmSound(
      id: 'default',
      name: 'Alarma Clásica',
      assetPath: 'audios/alarmaClasica.mp3',
      description: 'Sonido de alarma tradicional',
    ),
    AlarmSound(
      id: 'gentle',
      name: 'Despertar Suave',
      assetPath: 'audios/despertarSuave.mp3',
      description: 'Sonido más suave para despertar',
    ),
    AlarmSound(
      id: 'urgent',
      name: 'Alarma Urgente',
      assetPath: 'audios/alarmaUrgente.mp3',
      description: 'Sonido más intenso y urgente',
    ),
    AlarmSound(
      id: 'nature',
      name: 'Sonidos de la Naturaleza',
      assetPath: 'audios/alarmaNaturaleza.mp3',
      description: 'Sonidos relajantes de la naturaleza',
    ),
    AlarmSound(
      id: 'tropical',
      name: 'Alarm Tropical',
      assetPath: 'audios/alarmaTropical.mp3',
      description: 'Sonido tropical',
    ),
  ];

  static List<AlarmSound> get availableSounds => _availableSounds;

  static AlarmSound? getSoundById(String id) {
    try {
      return _availableSounds.firstWhere((sound) => sound.id == id);
    } catch (e) {
      return null;
    }
  }

  static AlarmSound getDefaultSound() {
    return _availableSounds.first;
  }

  static String getDefaultSoundId() {
    return _availableSounds.first.id;
  }
}
