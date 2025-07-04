import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttProvider extends ChangeNotifier {
  static const String brokerUrl =
      '58d91065580a4fdcac25c647bdab7643.s1.eu.hivemq.cloud';
  static const int brokerPort = 8883;
  static const String username = 'haquanghuy902';
  static const String password = 'Huy123456';

  MqttServerClient? _client;
  bool _isConnected = false;

  // Sensor data
  double _temperature = 0.0;
  double _humidity = 0.0;
  double _gasPpm = 0.0;
  bool _fireAlert = false;

  // Device data cho plugs
  Map<int, Map<String, dynamic>> _deviceData = {};

  String? _mqttTopicData;
  String? _mqttTopicControl;

  // Getters
  bool get isConnected => _isConnected;
  double get temperature => _temperature;
  double get humidity => _humidity;
  double get gasPpm => _gasPpm;
  bool get fireAlert => _fireAlert;
  Map<int, Map<String, dynamic>> get deviceData => _deviceData;

  // Kết nối MQTT
  Future<bool> connect(String clientId,
      {String? topicData, String? topicControl}) async {
    try {
      _client = MqttServerClient.withPort(brokerUrl, clientId, brokerPort);
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = true;

      final connMessage = MqttConnectMessage()
          .authenticateAs(username, password)
          .withWillTopic('willtopic')
          .withWillMessage('My Will message')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        _mqttTopicData = topicData;
        _mqttTopicControl = topicControl;

        // Subscribe to data topic if provided
        if (topicData != null) {
          _subscribeToTopic(topicData);
        }

        // Setup message listener
        _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
          final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
          final String message =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          _handleMessage(c[0].topic, message);
        });

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
      _isConnected = false;
      notifyListeners();
    }
    return false;
  }

  // Subscribe to topic
  void _subscribeToTopic(String topic) {
    if (_client != null && _isConnected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('Subscribed to topic: $topic');
    }
  }

  // Xử lý message nhận được
  void _handleMessage(String topic, String message) {
    try {
      final data = jsonDecode(message);
      debugPrint('Received message on $topic: $message');

      // Xử lý dữ liệu sensor (temperature, humidity, gas)
      if (data.containsKey('temperature')) {
        _temperature = (data['temperature'] ?? 0.0).toDouble();
      }
      if (data.containsKey('humidity')) {
        _humidity = (data['humidity'] ?? 0.0).toDouble();
      }
      if (data.containsKey('gas_ppm')) {
        _gasPpm = (data['gas_ppm'] ?? 0.0).toDouble();
      }
      if (data.containsKey('fire')) {
        _fireAlert = data['fire'] == true || data['fire'] == 1;
      }

      // Xử lý dữ liệu device (plug1, plug2)
      for (int i = 1; i <= 2; i++) {
        String deviceKey = 'device$i';
        if (data.containsKey(deviceKey)) {
          _deviceData[i] = Map<String, dynamic>.from(data[deviceKey]);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing MQTT message: $e');
    }
  }

  // Gửi lệnh điều khiển
  Future<void> publishCommand(String command, {int? plugNumber}) async {
    if (_client == null || !_isConnected || _mqttTopicControl == null) {
      debugPrint('MQTT not connected or no control topic');
      return;
    }

    try {
      Map<String, dynamic> commandData = {};

      if (plugNumber != null) {
        commandData['device$plugNumber'] = command;
      } else {
        commandData['command'] = command;
      }

      final message = jsonEncode(commandData);
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      _client!.publishMessage(
          _mqttTopicControl!, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Published command: $message to $_mqttTopicControl');
    } catch (e) {
      debugPrint('Error publishing command: $e');
    }
  }

  // Ngắt kết nối
  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _isConnected = false;
      _client = null;
      notifyListeners();
    }
  }

  // Reset fire alert
  void resetFireAlert() {
    _fireAlert = false;
    notifyListeners();
  }

  // Get device data for specific plug
  Map<String, dynamic>? getDeviceData(int plugNumber) {
    return _deviceData[plugNumber];
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
