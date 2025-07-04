import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/mqtt_provider.dart';
import '../providers/charging_provider.dart';
import '../providers/auth_provider.dart';

class PlugScreen extends StatefulWidget {
  final int plugNumber;

  const PlugScreen({super.key, required this.plugNumber});

  @override
  State<PlugScreen> createState() => _PlugScreenState();
}

class _PlugScreenState extends State<PlugScreen> {
  bool _isDeviceOn = false;
  Map<String, dynamic>? _deviceData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Ổ cắm ${widget.plugNumber}'),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: Consumer3<MqttProvider, ChargingProvider, AuthProvider>(
        builder:
            (context, mqttProvider, chargingProvider, authProvider, child) {
          _deviceData = mqttProvider.getDeviceData(widget.plugNumber);
          _isDeviceOn =
              _deviceData?['status']?.toString().toLowerCase() == 'on';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(),

                const SizedBox(height: 24),

                // Control button
                _buildControlButton(mqttProvider),

                const SizedBox(height: 24),

                // Electrical data
                _buildElectricalData(),

                const SizedBox(height: 24),

                // Charging info
                _buildChargingInfo(chargingProvider),

                const SizedBox(height: 24),

                // Save data button
                if (_isDeviceOn && _deviceData != null)
                  _buildSaveDataButton(authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDeviceOn
              ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
              : [Colors.grey[600]!, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isDeviceOn ? const Color(0xFF4CAF50) : Colors.grey[600]!)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isDeviceOn ? Icons.electric_bolt : Icons.power_off,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ổ cắm ${widget.plugNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isDeviceOn ? 'Đang hoạt động' : 'Đã tắt',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _isDeviceOn ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(MqttProvider mqttProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isDeviceOn ? Colors.red : const Color(0xFF4CAF50))
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            mqttProvider.isConnected ? () => _toggleDevice(mqttProvider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDeviceOn ? Colors.red : const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDeviceOn ? Icons.stop : Icons.play_arrow,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _isDeviceOn ? 'Dừng sạc' : 'Bắt đầu sạc',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectricalData() {
    final voltage = _deviceData?['voltage']?.toDouble() ?? 0.0;
    final current = _deviceData?['current']?.toDouble() ?? 0.0;
    final power = _deviceData?['power']?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông số điện',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildElectricalCard(
                'Điện áp',
                '${voltage.toStringAsFixed(1)} V',
                Icons.flash_on,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildElectricalCard(
                'Dòng điện',
                '${current.toStringAsFixed(2)} A',
                Icons.bolt,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildElectricalCard(
          'Công suất',
          '${power.toStringAsFixed(1)} W',
          Icons.power,
          Colors.green,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildElectricalCard(
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChargingInfo(ChargingProvider chargingProvider) {
    final energy = _deviceData?['energy']?.toDouble() ?? 0.0;
    final time = _deviceData?['time']?.toInt() ?? 0;
    final price = chargingProvider.calculatePrice(energy);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin sạc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                    'Thời gian', chargingProvider.formatTime(time)),
              ),
              Expanded(
                child: _buildInfoItem(
                    'Năng lượng', '${energy.toStringAsFixed(3)} kWh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveDataButton(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _saveDataToFirebase(authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2196F3),
          side: const BorderSide(color: Color(0xFF2196F3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.save),
        label: const Text(
          'Lưu dữ liệu vào Firebase',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _toggleDevice(MqttProvider mqttProvider) {
    final command = _isDeviceOn ? 'off' : 'on';
    mqttProvider.publishCommand(command, plugNumber: widget.plugNumber);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDeviceOn ? 'Đã tắt ổ cắm' : 'Đã bật ổ cắm'),
        backgroundColor: _isDeviceOn ? Colors.red : const Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _saveDataToFirebase(AuthProvider authProvider) async {
    if (_deviceData == null || authProvider.uid == null) return;

    try {
      final database = FirebaseDatabase.instance.ref();
      final now = DateTime.now();
      final sessionId = 'session_${now.millisecondsSinceEpoch}';

      final sessionData = {
        'userId': authProvider.uid,
        'plugNumber': widget.plugNumber,
        'startTime': now.toIso8601String(),
        'endTime': now.toIso8601String(),
        'energy': _deviceData!['energy'] ?? 0.0,
        'time': _deviceData!['time'] ?? 0,
        'voltage': _deviceData!['voltage'] ?? 0.0,
        'current': _deviceData!['current'] ?? 0.0,
        'power': _deviceData!['power'] ?? 0.0,
        'totalPrice': Provider.of<ChargingProvider>(context, listen: false)
            .calculatePrice((_deviceData!['energy'] ?? 0.0).toDouble()),
      };

      await database.child('Sessions').child(sessionId).set(sessionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu dữ liệu thành công!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
