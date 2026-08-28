import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/services/connectivity_service.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  _NetworkWrapperState createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    _networkService.initialize(context);
  }

  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
