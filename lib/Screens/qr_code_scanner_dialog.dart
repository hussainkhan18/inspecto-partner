// import 'package:flutter/material.dart';
// import 'package:inspecto_shield_partner/Screens/new_inspection.dart';
// import 'dart:convert';

// class QRViewExample extends StatefulWidget {
//   int id;
//   String name;
//   String company;
//   String branch;
//   String email;
//   String password;
//   String image;
//   String contact;

//   QRViewExample({
//     super.key,
//     required this.id,
//     required this.name,
//     required this.company,
//     required this.branch,
//     required this.email,
//     required this.password,
//     required this.image,
//     required this.contact,
//   });

//   @override
//   State<StatefulWidget> createState() => _QRViewExampleState();
// }

// class _QRViewExampleState extends State<QRViewExample> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   Barcode? result;
//   QRViewController? controller;

//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       if (mounted) {
//         controller!.pauseCamera();
//         controller!.resumeCamera();
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('QR Code Scanner'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             flex: 5,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//               overlay: QrScannerOverlayShape(
//                 borderColor: Colors.red,
//                 borderRadius: 20,
//                 borderLength: 50,
//                 borderWidth: 10,
//                 cutOutSize: 200,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: Text('Scan a code'),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });
//     controller.scannedDataStream.listen((scanData) async {
//       if (result == null) {
//         setState(() {
//           result = scanData;
//         });
//         await controller.pauseCamera(); // Pause the camera after scanning
//         try {
//           var jsonData = jsonDecode(result!.code!);
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => NewInspection(
//                 data: jsonData,
//                 id: widget.id,
//                 name: widget.name,
//                 branch: widget.branch,
//                 company: widget.company,
//                 email: widget.email,
//                 password: widget.password,
//                 image: widget.image,
//                 contact: widget.contact,
//               ),
//             ),
//           ).then((_) {
//             // Resume the camera when coming back from the NewInspection
//             controller.resumeCamera();
//             setState(() {
//               result = null;
//             });
//           });
//         } catch (e) {
//           print('Error decoding QR code: $e'); // Debug statement
//           controller.resumeCamera();
//           setState(() {
//             result = null;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text('Failed to decode QR code. Please try again.')),
//           );
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
