import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<HistoryItem> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<HistoryItem> get historyList => _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Lấy UID hiện tại từ SharedPreferences
  Future<String?> _getCurrentUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('UID');
  }

  // Lấy dữ liệu lịch sử từ Firebase
  Future<void> fetchHistoryData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = await _getCurrentUID();
      if (uid == null) {
        _errorMessage = 'Không tìm thấy UID! Người dùng chưa đăng nhập.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('Đang lấy lịch sử của UID: $uid');

      final snapshot =
          await _database.child('Users').child(uid).child('datahistory').once();

      _historyList.clear();

      if (!snapshot.snapshot.exists) {
        debugPrint('⚠ Không tìm thấy lịch sử sạc của UID: $uid');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final dynamic rawData = snapshot.snapshot.value;
      debugPrint('Raw data type: ${rawData.runtimeType}');
      debugPrint('Raw data: $rawData');

      // Xử lý dữ liệu tùy theo kiểu
      if (rawData is Map) {
        final historyData = Map<String, dynamic>.from(rawData);
        _processHistoryData(historyData);
      } else if (rawData is List) {
        // Nếu là List, chuyển đổi thành Map với key là index
        final historyData = <String, dynamic>{};
        for (int i = 0; i < rawData.length; i++) {
          if (rawData[i] != null) {
            historyData[i.toString()] = rawData[i];
          }
        }
        _processHistoryData(historyData);
      } else {
        debugPrint('⚠ Kiểu dữ liệu không được hỗ trợ: ${rawData.runtimeType}');
        _errorMessage = 'Định dạng dữ liệu không hợp lệ';
      }

      // Sắp xếp theo thời gian (mới nhất trước)
      _historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('Đã tải lịch sử thành công! Số lượng: ${_historyList.length}');
    } catch (e) {
      _errorMessage = 'Lỗi Firebase: $e';
      debugPrint('Lỗi khi lấy dữ liệu lịch sử: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Xử lý dữ liệu lịch sử
  void _processHistoryData(Map<String, dynamic> historyData) {
    for (var entry in historyData.entries) {
      final key = entry.key;
      final itemData = entry.value;

      // Kiểm tra xem itemData có phải là Map không
      if (itemData is Map) {
        final data = Map<String, dynamic>.from(itemData);

        final timestamp = data['timestamp']?.toString() ?? '';
        final timeuse = data['timeuse']?.toString() ?? '';
        final energy = data['energy']?.toString() ?? '0';
        final power = data['power']?.toString() ?? '0';
        final price = data['price']?.toString() ?? '0';
        final plugNumber = data['plugNumber']?.toString() ?? '';

        _historyList.add(HistoryItem(
          key: key,
          timestamp: timestamp,
          timeuse: timeuse,
          plugNumber: plugNumber,
          energy: energy,
          power: power,
          price: price,
        ));
      } else {
        debugPrint('⚠ Item data không phải Map: $itemData');
      }
    }
  }

  // Làm mới dữ liệu
  Future<void> refreshHistory() async {
    await fetchHistoryData();
  }

  // Xóa lỗi
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Lấy chi tiết một item lịch sử
  HistoryItem? getHistoryItem(String key) {
    try {
      return _historyList.firstWhere((item) => item.key == key);
    } catch (e) {
      return null;
    }
  }

  // Lọc lịch sử theo plug number
  List<HistoryItem> getHistoryByPlug(String plugNumber) {
    return _historyList.where((item) => item.plugNumber == plugNumber).toList();
  }

  // Lọc lịch sử theo khoảng thời gian
  List<HistoryItem> getHistoryByDateRange(
      DateTime startDate, DateTime endDate) {
    return _historyList.where((item) {
      try {
        final itemDate = DateTime.parse(item.timestamp);
        return itemDate.isAfter(startDate) && itemDate.isBefore(endDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Tính tổng năng lượng đã sạc
  double getTotalEnergy() {
    return _historyList.fold(0.0, (sum, item) {
      try {
        return sum + double.parse(item.energy);
      } catch (e) {
        return sum;
      }
    });
  }

  // Tính tổng chi phí
  double getTotalCost() {
    return _historyList.fold(0.0, (sum, item) {
      try {
        return sum + double.parse(item.price);
      } catch (e) {
        return sum;
      }
    });
  }

  // Tính thời gian sạc tổng
  String getTotalUsageTime() {
    int totalMinutes = 0;
    for (var item in _historyList) {
      try {
        // Giả sử timeuse có format "HH:mm" hoặc "mm"
        final parts = item.timeuse.split(':');
        if (parts.length == 2) {
          totalMinutes += int.parse(parts[0]) * 60 + int.parse(parts[1]);
        } else {
          totalMinutes += int.parse(item.timeuse);
        }
      } catch (e) {
        // Bỏ qua nếu không parse được
      }
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
