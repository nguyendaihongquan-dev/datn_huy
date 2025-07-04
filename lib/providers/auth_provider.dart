import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('Users');

  String? _uid;
  String? _phoneNumber;
  String? _fullName;
  String? _address;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Getters
  String? get uid => _uid;
  String? get phoneNumber => _phoneNumber;
  String? get fullName => _fullName;
  String? get address => _address;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  // Khởi tạo và kiểm tra trạng thái đăng nhập
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString('UID');
    _phoneNumber = prefs.getString('PHONE');
    _fullName = prefs.getString('FULL_NAME');
    _address = prefs.getString('ADDRESS');

    if (_uid != null) {
      _isLoggedIn = true;
      // Lấy thông tin user từ Firebase
      await _fetchUserInfo();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Đăng nhập
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await _database.orderByChild('phoneNumber').equalTo(phone).once();

      if (snapshot.snapshot.value == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

      for (var entry in users.entries) {
        final userData = Map<String, dynamic>.from(entry.value);
        final storedPassword = userData['password']?.toString();

        if (storedPassword == password) {
          _uid = entry.key;
          _phoneNumber = phone;
          _fullName = userData['fullName']?.toString();
          _address = userData['address']?.toString();
          _isLoggedIn = true;

          // Lưu vào SharedPreferences
          await _saveUserData();

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    _uid = null;
    _phoneNumber = null;
    _fullName = null;
    _address = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  // Lưu dữ liệu user vào SharedPreferences
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_uid != null) await prefs.setString('UID', _uid!);
    if (_phoneNumber != null) await prefs.setString('PHONE', _phoneNumber!);
    if (_fullName != null) await prefs.setString('FULL_NAME', _fullName!);
    if (_address != null) await prefs.setString('ADDRESS', _address!);
  }

  // Lấy thông tin user từ Firebase
  Future<void> _fetchUserInfo() async {
    if (_uid == null) return;

    try {
      final snapshot = await _database.child(_uid!).once();
      if (snapshot.snapshot.value != null) {
        final userData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        _fullName = userData['fullName']?.toString();
        _address = userData['address']?.toString();
        await _saveUserData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  // Lấy dữ liệu lịch sử từ Firebase
  Future<List<HistoryItem>> getHistoryData(String uid) async {
    try {
      final snapshot = await _database.child(uid).child('datahistory').once();

      if (snapshot.snapshot.value == null) {
        return [];
      }

      final historyData =
          Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final List<HistoryItem> historyList = [];

      for (var entry in historyData.entries) {
        final itemData = Map<String, dynamic>.from(entry.value);
        historyList.add(HistoryItem.fromMap(itemData, entry.key));
      }

      // Sắp xếp theo thời gian (mới nhất trước)
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return historyList;
    } catch (e) {
      debugPrint('Error fetching history data: $e');
      return [];
    }
  }

  // Cập nhật thông tin người dùng
  Future<bool> updateUserInfo({
    required String fullName,
    required String address,
    required String phoneNumber,
  }) async {
    if (_uid == null) return false;

    try {
      await _database.child(_uid!).update({
        'fullName': fullName,
        'address': address,
        'phoneNumber': phoneNumber,
      });

      _fullName = fullName;
      _address = address;
      _phoneNumber = phoneNumber;

      await _saveUserData();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating user info: $e');
      return false;
    }
  }

  // Lấy thông tin chi tiết người dùng
  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      final snapshot = await _database.child(uid).once();
      if (snapshot.snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }
}
