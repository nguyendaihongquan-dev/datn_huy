import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charging_provider.dart';
import '../providers/mqtt_provider.dart';
import 'home_screen.dart';
import 'station_screen.dart';
import 'qr_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _initializeData();
  }

  void _initializeScreens() {
    _screens.clear();
    _screens.addAll([
      const HomeScreen(),
      const StationScreen(),
      QrScreen(onNavigateToStation: _navigateToStation),
      const HistoryScreen(),
      const ProfileScreen(),
    ]);
  }

  void _navigateToStation() {
    setState(() {
      _currentIndex = 1; // Chuyển đến tab Station (index 1)
    });
  }

  Future<void> _initializeData() async {
    final chargingProvider =
        Provider.of<ChargingProvider>(context, listen: false);
    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);

    // Load dữ liệu QR từ SharedPreferences
    await chargingProvider.loadQrData();

    // Kết nối MQTT nếu có dữ liệu
    if (chargingProvider.hasQrData && !mqttProvider.isConnected) {
      final clientId = 'FlutterClient-${DateTime.now().millisecondsSinceEpoch}';
      await mqttProvider.connect(
        clientId,
        topicData: chargingProvider.mqttTopicData,
        topicControl: chargingProvider.mqttTopicControl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? const Color(0xFF2196F3).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                ),
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? const Color(0xFF2196F3).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 1
                      ? Icons.electric_car
                      : Icons.electric_car_outlined,
                  size: 24,
                ),
              ),
              label: 'Trạm sạc',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? const Color(0xFF2196F3).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2
                      ? Icons.qr_code_scanner
                      : Icons.qr_code_scanner_outlined,
                  size: 24,
                ),
              ),
              label: 'Quét QR',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      ? const Color(0xFF2196F3).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 3 ? Icons.history : Icons.history_outlined,
                  size: 24,
                ),
              ),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 4
                      ? const Color(0xFF2196F3).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 4 ? Icons.person : Icons.person_outline,
                  size: 24,
                ),
              ),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
