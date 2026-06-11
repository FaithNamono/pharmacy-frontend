// lib/providers/backup_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class BackupProvider extends ChangeNotifier {
  bool _autoBackupEnabled = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _lastBackupInfo = 'No backups yet';
  String? _lastBackupTime;
  String? _error;
  String _backupLocation = 'Backup not available on web';
  List<Map<String, dynamic>> _backupHistory = [];

  BackupProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    if (!kIsWeb) {
      await _setupBackupLocation();
      await _loadBackupHistory();
    }
  }

  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  String get lastBackupInfo => _lastBackupInfo;
  String? get lastBackupTime => _lastBackupTime;
  String? get error => _error;
  String get backupLocation => _backupLocation;
  List<Map<String, dynamic>> get backupHistory => _backupHistory;

  String get nextBackupTime {
    if (!_autoBackupEnabled) return 'Disabled';
    final now = DateTime.now();
    var nextBackup = DateTime(now.year, now.month, now.day, 2);
    if (nextBackup.isBefore(now)) {
      nextBackup = nextBackup.add(const Duration(days: 1));
    }
    final hours = (nextBackup.difference(now).inHours).toString();
    return 'in $hours hours';
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoBackupEnabled = prefs.getBool('auto_backup') ?? false;
    _lastBackupTime = prefs.getString('last_backup_time');
    if (_lastBackupTime != null) {
      _lastBackupInfo = 'Last backup: ${_formatDate(DateTime.parse(_lastBackupTime!))}';
    }
    notifyListeners();
  }

  Future<void> _loadBackupHistory() async {
    if (kIsWeb) {
      _backupHistory = [];
      notifyListeners();
      return;
    }
    
    final backups = await getAvailableBackups();
    _backupHistory = backups;
    notifyListeners();
  }

  Future<void> _setupBackupLocation() async {
    if (kIsWeb) {
      _backupLocation = 'Backup not available on web';
      notifyListeners();
      return;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/dervin_pharmacy_backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      _backupLocation = backupDir.path;
    } catch (e) {
      _error = e.toString();
      _backupLocation = 'Error: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    _autoBackupEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup', enabled);
    
    if (enabled && !kIsWeb) {
      await _scheduleAutoBackup();
    }
    
    notifyListeners();
  }

  Future<void> _scheduleAutoBackup() async {
    await _checkAndPerformScheduledBackup();
  }

  Future<void> checkAutoBackup() async {
    if (_autoBackupEnabled && !kIsWeb) {
      await _checkAndPerformScheduledBackup();
    }
  }

  Future<void> _checkAndPerformScheduledBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_backup_time');
    
    if (lastBackup != null) {
      final lastBackupDate = DateTime.parse(lastBackup);
      final now = DateTime.now();
      
      if (now.difference(lastBackupDate).inHours >= 24) {
        await performBackup(auto: true);
      }
    } else {
      await performBackup(auto: true);
    }
  }

  Future<bool> performBackup({bool auto = false}) async {
    if (kIsWeb) {
      _error = 'Backup is not supported on web. Please use mobile or desktop version.';
      notifyListeners();
      return false;
    }
    
    _isBackingUp = true;
    _error = null;
    notifyListeners();

    try {
      // Create backup data structure
      final backupData = <String, dynamic>{};
      
      // Add metadata
      final timestamp = DateTime.now();
      backupData['_metadata'] = {
        'version': '1.0.0',
        'timestamp': timestamp.toIso8601String(),
        'app_name': 'Dervin Pharmacy',
        'auto_backup': auto,
      };
      
      // Add settings
      final prefs = await SharedPreferences.getInstance();
      backupData['settings'] = {
        'auto_backup': prefs.getBool('auto_backup'),
        'language': prefs.getString('language'),
        'theme_mode': prefs.getString('theme_mode'),
      };
      
      // Save to file
      final backupFileName = 'backup_${timestamp.year}_${timestamp.month}_${timestamp.day}_${timestamp.hour}_${timestamp.minute}.json';
      final backupFile = File('$_backupLocation/$backupFileName');
      await backupFile.writeAsString(jsonEncode(backupData));
      
      // Clean old backups (keep only last 10)
      await _cleanOldBackups();
      
      // Update last backup info
      _lastBackupTime = timestamp.toIso8601String();
      _lastBackupInfo = 'Last backup: ${_formatDate(timestamp)}';
      
      await prefs.setString('last_backup_time', _lastBackupTime!);
      await prefs.setString('last_backup_file', backupFileName);
      
      // Refresh backup history
      await _loadBackupHistory();
      
      _isBackingUp = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isBackingUp = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreBackup(String backupPath) async {
    if (kIsWeb) {
      _error = 'Restore is not supported on web. Please use mobile or desktop version.';
      notifyListeners();
      return false;
    }
    
    _isRestoring = true;
    _error = null;
    notifyListeners();

    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }
      
      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
      
      // Restore settings
      if (backupData['settings'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final settings = backupData['settings'] as Map<String, dynamic>;
        
        if (settings['auto_backup'] != null) {
          await prefs.setBool('auto_backup', settings['auto_backup'] as bool);
          _autoBackupEnabled = settings['auto_backup'] as bool;
        }
        if (settings['language'] != null) {
          await prefs.setString('language', settings['language'] as String);
        }
        if (settings['theme_mode'] != null) {
          await prefs.setString('theme_mode', settings['theme_mode'] as String);
        }
      }
      
      _isRestoring = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isRestoring = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    if (kIsWeb) {
      return [];
    }
    
    final backups = <Map<String, dynamic>>[];
    final backupDir = Directory(_backupLocation);
    
    try {
      if (await backupDir.exists()) {
        final files = await backupDir.list().toList();
        
        for (var file in files) {
          if (file is File && file.path.endsWith('.json')) {
            final fileName = file.path.split('/').last;
            final fileStat = await file.stat();
            
            try {
              final content = await file.readAsString();
              final data = jsonDecode(content);
              final metadata = data['_metadata'] ?? {};
              
              backups.add({
                'name': fileName,
                'path': file.path,
                'date': _formatDate(fileStat.modified),
                'size': _formatBytes(fileStat.size),
                'auto_backup': metadata['auto_backup'] ?? false,
                'timestamp': metadata['timestamp'] ?? fileStat.modified.toIso8601String(),
              });
            } catch (e) {
              backups.add({
                'name': fileName,
                'path': file.path,
                'date': _formatDate(fileStat.modified),
                'size': _formatBytes(fileStat.size),
                'auto_backup': false,
                'timestamp': fileStat.modified.toIso8601String(),
              });
            }
          }
        }
        
        backups.sort((a, b) => b['date'].compareTo(a['date']));
      }
    } catch (e) {
      _error = e.toString();
    }
    
    return backups;
  }

  Future<void> deleteBackup(String backupPath) async {
    if (kIsWeb) return;
    
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        await _loadBackupHistory();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _cleanOldBackups() async {
    if (kIsWeb) return;
    
    final backups = await getAvailableBackups();
    if (backups.length > 10) {
      for (int i = 10; i < backups.length; i++) {
        final file = File(backups[i]['path']);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}