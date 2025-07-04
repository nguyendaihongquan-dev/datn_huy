import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charging_provider.dart';
import '../providers/mqtt_provider.dart';
import 'plug_screen.dart';

class StationScreen extends StatelessWidget {
  const StationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trạm sạc'),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: Consumer2<ChargingProvider, MqttProvider>(
        builder: (context, chargingProvider, mqttProvider, child) {
          if (!chargingProvider.hasQrData) {
            return _buildNoDataView();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin trạm
                _buildStationInfo(chargingProvider, mqttProvider),

                const SizedBox(height: 24),

                // Nút Start/Stop
                _buildControlButton(context, chargingProvider, mqttProvider),

                const SizedBox(height: 32),

                // Danh sách ổ cắm
                _buildPlugsList(context, chargingProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa quét QR code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng quét QR code trên trạm sạc để bắt đầu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStationInfo(
      ChargingProvider chargingProvider, MqttProvider mqttProvider) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.electric_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạm sạc',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      chargingProvider.deviceId ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: mqttProvider.isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem('Số ổ cắm', '${chargingProvider.plugs}'),
              const SizedBox(width: 32),
              _buildInfoItem('Trạng thái',
                  mqttProvider.isConnected ? 'Hoạt động' : 'Offline'),
            ],
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(BuildContext context,
      ChargingProvider chargingProvider, MqttProvider mqttProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: chargingProvider.isCharging
                ? Colors.red.withOpacity(0.3)
                : const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: mqttProvider.isConnected
            ? () => _toggleCharging(context, chargingProvider, mqttProvider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: chargingProvider.isCharging
              ? Colors.red
              : const Color(0xFF4CAF50),
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
              chargingProvider.isCharging ? Icons.stop : Icons.play_arrow,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              chargingProvider.isCharging ? 'Dừng trạm' : 'Khởi động trạm',
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

  Widget _buildPlugsList(
      BuildContext context, ChargingProvider chargingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ổ cắm sạc',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chargingProvider.plugs,
          itemBuilder: (context, index) {
            final plugNumber = index + 1;
            return _buildPlugCard(context, chargingProvider, plugNumber);
          },
        ),
      ],
    );
  }

  Widget _buildPlugCard(
      BuildContext context, ChargingProvider chargingProvider, int plugNumber) {
    final isEnabled = chargingProvider.isCharging;
    final isSelected = chargingProvider.selectedPlug == plugNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () => _selectPlug(context, chargingProvider, plugNumber)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? (isSelected
                            ? const Color(0xFF2196F3)
                            : const Color(0xFF4CAF50))
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.electric_bolt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ổ cắm $plugNumber',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isEnabled
                            ? (isSelected ? 'Đã chọn' : 'Sẵn sàng')
                            : 'Không khả dụng',
                        style: TextStyle(
                          fontSize: 12,
                          color: isEnabled
                              ? (isSelected
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFF4CAF50))
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEnabled)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCharging(BuildContext context, ChargingProvider chargingProvider,
      MqttProvider mqttProvider) {
    final isCharging = chargingProvider.isCharging;

    if (isCharging) {
      // Dừng charging
      _showStopDialog(context, chargingProvider, mqttProvider);
    } else {
      // Bắt đầu charging
      chargingProvider.setChargingState(true);
      mqttProvider.publishCommand('start');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khởi động trạm sạc'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  void _showStopDialog(BuildContext context, ChargingProvider chargingProvider,
      MqttProvider mqttProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dừng trạm sạc'),
        content: const Text(
            'Bạn có chắc chắn muốn dừng trạm sạc? Điều này sẽ ngắt kết nối và xóa dữ liệu session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Dừng charging và xóa session
              chargingProvider.setChargingState(false);
              await mqttProvider.publishCommand('stop');
              await chargingProvider.clearSession();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã dừng trạm sạc và xóa session'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Dừng'),
          ),
        ],
      ),
    );
  }

  void _selectPlug(
      BuildContext context, ChargingProvider chargingProvider, int plugNumber) {
    if (!chargingProvider.isCharging) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng khởi động trạm trước!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    chargingProvider.selectPlug(plugNumber);

    // Navigate to PlugScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlugScreen(plugNumber: plugNumber),
      ),
    );
  }
}
