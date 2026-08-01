import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shieldconnect_app/model/dhsi_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/local_db_service.dart';

class DhsiController extends ChangeNotifier {
  bool _isLoading = false;
  DhsiData? _dhsiData;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  DhsiData? get dhsiData => _dhsiData;
  String? get errorMessage => _errorMessage;

  Future<void> loadCachedDhsiData(String userId) async {
    try {
      final cachedJson = await LocalDbService().getDhsiCache(userId);
      if (cachedJson != null) {
        final dhsiResponse = DhsiResponse.fromJson(cachedJson);
        if (dhsiResponse.success && dhsiResponse.data != null) {
          _dhsiData = dhsiResponse.data;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error loading cached DHSI data: $e");
    }
  }

  Future<void> fetchDhsiData(String userId) async {
    if (userId.isEmpty) return;

    // Load cached data first
    await loadCachedDhsiData(userId);

    // Show loading spinner ONLY if there is no cached data
    if (_dhsiData == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await ApiService().get('/dhsi?userId=$userId');
      final dynamic responseData = response.data;
      
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      final dhsiResponse = DhsiResponse.fromJson(json);

      if (dhsiResponse.success && dhsiResponse.data != null) {
        _dhsiData = dhsiResponse.data;
        _errorMessage = null;
        await LocalDbService().saveDhsiCache(userId, json);
      } else {
        if (_dhsiData == null) {
          _errorMessage = "Failed to load safety index data.";
        }
      }
    } catch (e) {
      debugPrint("Error fetching DHSI data: $e");
      if (_dhsiData == null) {
        _errorMessage = "Connection error. Please try again.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
