import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      _profiles = await _api.getProfiles();
    } catch (e, stack) {
      debugPrint('=== PROFILES ERROR: $e');
      debugPrint('=== STACK: $stack');
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
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
