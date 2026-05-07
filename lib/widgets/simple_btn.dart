import 'package:flutter/material.dart';
import '../helper/style.dart' as style;

class SimpleButton extends StatelessWidget {
  final String btnName;
  final VoidCallback onPressed;

  const SimpleButton(
      {super.key, required this.btnName, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: onPressed,
        style: style.simpleButton(),
        child: Text(btnName),
      ),
    );
  }
}
