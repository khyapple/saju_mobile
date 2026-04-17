import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfilesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Profile> _profiles = [];
  bool _loading = false;
  String? _error;

  List<Profile> get profiles => _profiles;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProfiles() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _api.getProfiles();
      _profiles = await _applySavedOrder(fetched);
    } catch (e, stack) {
      debugPrint('=== PROFILES ERROR: $e');
      debugPrint('=== STACK: $stack');
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Profile>> _applySavedOrder(List<Profile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('profile_order');
      if (ids == null || ids.isEmpty) return profiles;
      final ordered = <Profile>[];
      for (final id in ids) {
        final matches = profiles.where((p) => p.id == id);
        if (matches.isNotEmpty) ordered.add(matches.first);
      }
      for (final p in profiles) {
        if (!ordered.any((o) => o.id == p.id)) ordered.add(p);
      }
      return ordered;
    } catch (_) {
      return profiles;
    }
  }

  void reorderProfiles(List<Profile> newOrder) {
    _profiles = List.from(newOrder);
    notifyListeners();
    _saveOrder();
  }

  Future<void> _saveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _profiles.map((p) => p.id).toList();
      await prefs.setStringList('profile_order', ids);
    } catch (e) {
      debugPrint('Failed to save profile order: $e');
    }
  }

  Future<void> deleteProfile(String profileId) async {
    await _api.deleteProfile(profileId);
    _profiles.removeWhere((p) => p.id == profileId);
    notifyListeners();
  }

  void clear() {
    _profiles = [];
    notifyListeners();
  }
}
