import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChargingProvider extends ChangeNotifier {
  // QR Code data
  String? _deviceId;
  int _plugs = 2;
  String? _mqttTopicData;
  String? _mqttTopicControl;

  // Charging session
  bool _isCharging = false;
  int? _selectedPlug;

  // Pricing
  static const int baseFee = 4000; // Phí khởi tạo
  static const int pricePerKwh = 3000; // Giá 1 kWh

  // Getters
  String? get deviceId => _deviceId;
  int get plugs => _plugs;
  String? get mqttTopicData => _mqttTopicData;
  String? get mqttTopicControl => _mqttTopicControl;
  bool get isCharging => _isCharging;
  int? get selectedPlug => _selectedPlug;

  // Lưu dữ liệu QR code
  Future<void> saveQrData({
    required String deviceId,
    required int plugs,
    required String mqttTopicData,
    required String mqttTopicControl,
  }) async {
    _deviceId = deviceId;
    _plugs = plugs;
    _mqttTopicData = mqttTopicData;
    _mqttTopicControl = mqttTopicControl;

    // Lưu vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceId', deviceId);
    await prefs.setInt('plugs', plugs);
    await prefs.setString('mqttTopicData', mqttTopicData);
    await prefs.setString('mqttTopicControl', mqttTopicControl);

    notifyListeners();
  }

  // Load dữ liệu từ SharedPreferences
  Future<void> loadQrData() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('deviceId');
    _plugs = prefs.getInt('plugs') ?? 2;
    _mqttTopicData = prefs.getString('mqttTopicData');
    _mqttTopicControl = prefs.getString('mqttTopicControl');

    notifyListeners();
  }

  // Bắt đầu/Dừng charging session
  void setChargingState(bool isCharging) {
    _isCharging = isCharging;
    if (!isCharging) {
      _selectedPlug = null;
    }
    notifyListeners();
  }

  // Chọn plug
  void selectPlug(int plugNumber) {
    if (plugNumber >= 1 && plugNumber <= _plugs) {
      _selectedPlug = plugNumber;
      notifyListeners();
    }
  }

  // Tính toán giá tiền
  int calculatePrice(double energy) {
    return baseFee + (energy * pricePerKwh).round();
  }

  // Format thời gian từ giây
  String formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Xóa dữ liệu session
  Future<void> clearSession() async {
    _deviceId = null;
    _mqttTopicData = null;
    _mqttTopicControl = null;
    _isCharging = false;
    _selectedPlug = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deviceId');
    await prefs.remove('mqttTopicData');
    await prefs.remove('mqttTopicControl');

    notifyListeners();
  }

  // Kiểm tra xem có dữ liệu QR không
  bool get hasQrData =>
      _deviceId != null && _mqttTopicData != null && _mqttTopicControl != null;
}
