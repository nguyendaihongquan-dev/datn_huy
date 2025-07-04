import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mqtt_provider.dart';
import '../providers/charging_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer3<AuthProvider, MqttProvider, ChargingProvider>(
          builder:
              (context, authProvider, mqttProvider, chargingProvider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                // Refresh MQTT connection if needed
                if (chargingProvider.hasQrData && !mqttProvider.isConnected) {
                  final clientId =
                      'FlutterClient-${DateTime.now().millisecondsSinceEpoch}';
                  await mqttProvider.connect(
                    clientId,
                    topicData: chargingProvider.mqttTopicData,
                    topicControl: chargingProvider.mqttTopicControl,
                  );
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header với thông tin user
                    _buildHeader(authProvider),

                    const SizedBox(height: 24),

                    // Trạng thái kết nối
                    _buildConnectionStatus(mqttProvider, chargingProvider),

                    const SizedBox(height: 24),

                    // Cảnh báo cháy (nếu có)
                    if (mqttProvider.fireAlert) ...[
                      _buildFireAlert(context, mqttProvider),
                      const SizedBox(height: 24),
                    ],

                    // Dữ liệu sensor
                    _buildSensorData(mqttProvider),

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(context, chargingProvider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  authProvider.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.phoneNumber ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _showLogoutDialog(authProvider);
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(
      MqttProvider mqttProvider, ChargingProvider chargingProvider) {
    final isConnected = mqttProvider.isConnected;
    final hasQrData = chargingProvider.hasQrData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Đã kết nối MQTT' : 'Chưa kết nối MQTT',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hasQrData
                      ? 'Trạm: ${chargingProvider.deviceId ?? "N/A"}'
                      : 'Chưa quét QR code',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireAlert(BuildContext context, MqttProvider mqttProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo cháy!',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Đã phát hiện lửa tại trạm sạc',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              mqttProvider.resetFireAlert();
            },
            child: const Text('Đã xử lý'),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorData(MqttProvider mqttProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dữ liệu cảm biến',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'Nhiệt độ',
                '${mqttProvider.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorCard(
                'Độ ẩm',
                '${mqttProvider.humidity.toStringAsFixed(1)}%',
                Icons.water_drop,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          'Khí Gas',
          '${mqttProvider.gasPpm.toStringAsFixed(1)} PPM',
          Icons.air,
          Colors.purple,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSensorCard(
      String title, String value, IconData icon, Color color,
      {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, ChargingProvider chargingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (!chargingProvider.hasQrData) ...[
                const Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quét QR Code để bắt đầu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quét mã QR trên trạm sạc để kết nối và điều khiển',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Icon(
                  Icons.electric_car,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đã kết nối trạm sạc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trạm: ${chargingProvider.deviceId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    // Placeholder for logout functionality
    // User can click on profile image to logout
  }
}
