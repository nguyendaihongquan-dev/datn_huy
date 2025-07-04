import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/charging_provider.dart';
import '../providers/mqtt_provider.dart';

class QrScreen extends StatefulWidget {
  final VoidCallback? onNavigateToStation;

  const QrScreen({super.key, this.onNavigateToStation});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  MobileScannerController? controller;
  bool isScanning = false;
  bool isFlashOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on),
            onPressed: () async {
              await controller?.toggleTorch();
              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null && !isScanning) {
                        _handleQRCodeResult(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                // Custom overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: const Color(0xFF2196F3),
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 8,
                      cutOutSize: 250,
                    ),
                  ),
                ),
                // Scanning indicator
                if (isScanning)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quét mã QR trên trạm sạc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đưa camera đến mã QR để quét và kết nối',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQRCodeResult(String qrCode) async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    await controller?.stop();

    try {
      // Parse QR code JSON
      final data = jsonDecode(qrCode);

      final deviceId = data['deviceId'] as String?;
      final plugs = (data['plugs'] as num?)?.toInt() ?? 2;
      final mqttTopicData = data['mqttTopicData'] as String?;
      final mqttTopicControl = data['mqttTopicControl'] as String?;

      if (deviceId == null ||
          mqttTopicData == null ||
          mqttTopicControl == null) {
        throw const FormatException('Thiếu thông tin trong QR code');
      }

      if (mounted) {
        final chargingProvider =
            Provider.of<ChargingProvider>(context, listen: false);
        final mqttProvider = Provider.of<MqttProvider>(context, listen: false);

        // Lưu dữ liệu QR
        await chargingProvider.saveQrData(
          deviceId: deviceId,
          plugs: plugs,
          mqttTopicData: mqttTopicData,
          mqttTopicControl: mqttTopicControl,
        );

        // Kết nối MQTT
        final clientId =
            'FlutterClient-${DateTime.now().millisecondsSinceEpoch}';
        final success = await mqttProvider.connect(
          clientId,
          topicData: mqttTopicData,
          topicControl: mqttTopicControl,
        );

        if (success) {
          _showSuccessDialog(deviceId);
        } else {
          _showErrorDialog('Không thể kết nối MQTT');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('QR code không hợp lệ: ${e.toString()}');
      }
    }

    setState(() {
      isScanning = false;
    });
  }

  void _showSuccessDialog(String deviceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Kết nối thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đã kết nối với trạm sạc: $deviceId'),
            const SizedBox(height: 16),
            const Text(
              'Bạn có thể bắt đầu sử dụng trạm sạc ngay bây giờ.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Chuyển đến tab Station
              if (mounted) {
                widget.onNavigateToStation?.call();
              }
            },
            child: const Text('Đến trạm sạc'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: Colors.red,
          size: 48,
        ),
        title: const Text('Lỗi quét QR'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller?.start();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width * 0.1;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength =
        borderLength > cutOutSize ? borderLength : cutOutSize * 0.1;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    // Draw corners
    final topLeft = cutOutRect.topLeft;
    final topRight = cutOutRect.topRight;
    final bottomLeft = cutOutRect.bottomLeft;
    final bottomRight = cutOutRect.bottomRight;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(topLeft.dx, topLeft.dy + _borderLength)
        ..lineTo(topLeft.dx, topLeft.dy)
        ..lineTo(topLeft.dx + _borderLength, topLeft.dy),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(topRight.dx - _borderLength, topRight.dy)
        ..lineTo(topRight.dx, topRight.dy)
        ..lineTo(topRight.dx, topRight.dy + _borderLength),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(bottomLeft.dx, bottomLeft.dy - _borderLength)
        ..lineTo(bottomLeft.dx, bottomLeft.dy)
        ..lineTo(bottomLeft.dx + _borderLength, bottomLeft.dy),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(bottomRight.dx - _borderLength, bottomRight.dy)
        ..lineTo(bottomRight.dx, bottomRight.dy)
        ..lineTo(bottomRight.dx, bottomRight.dy - _borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is QrScannerOverlayShape) {
      return QrScannerOverlayShape(
        borderColor: Color.lerp(a.borderColor, borderColor, t)!,
        borderWidth: lerpDouble(a.borderWidth, borderWidth, t)!,
        overlayColor: Color.lerp(a.overlayColor, overlayColor, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is QrScannerOverlayShape) {
      return QrScannerOverlayShape(
        borderColor: Color.lerp(borderColor, b.borderColor, t)!,
        borderWidth: lerpDouble(borderWidth, b.borderWidth, t)!,
        overlayColor: Color.lerp(overlayColor, b.overlayColor, t)!,
      );
    }
    return super.lerpTo(b, t);
  }
}
