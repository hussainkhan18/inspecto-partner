//   import 'dart:convert';
// import 'package:flutter/material.dart';

// class QRScannerScreen extends StatefulWidget {
//   @override
//   _QRScannerScreenState createState() => _QRScannerScreenState();
// }

// class _QRScannerScreenState extends State<QRScannerScreen> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
  
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       controller!.resumeCamera();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Scan QR Code')),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 4,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: Text('Scan a QR code to proceed'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) {
//       if (scanData.code != null) {
//         controller.dispose(); // Stop scanning

//         final scannedData = scanData.code!;

//         if (scannedData.trim().startsWith('{')) {
//           try {
//             final decodedData = json.decode(scannedData);
//             if (decodedData is Map) {
//               Navigator.pop(context, decodedData); // Return scanned data
//             }
//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Invalid QR code format')),
//             );
//           }
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
// }
