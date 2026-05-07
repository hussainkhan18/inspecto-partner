import 'package:flutter/material.dart';

// const appColor = Color(0xff00C0C8);
const appColor = Color(0xff0dc5b9);

inputTextFieldDecoration(val, icn) {
  return InputDecoration(
    contentPadding: const EdgeInsets.all(0),
    labelText: '$val',
    floatingLabelStyle: const TextStyle(color: Colors.grey),
    suffixIcon: icn != '' ? Icon(icn, color: appColor) : null,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(width: 2, color: (Colors.grey[300])!)),
    focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(width: 2, color: appColor)),
  );
}

simpleButton() {
  return ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: appColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      elevation: 0,
      textStyle: const TextStyle(
          fontFamily: 'medium', letterSpacing: 0.5, fontSize: 16));
}

outlineButton() {
  return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      elevation: 0,
      textStyle: const TextStyle(
        fontFamily: 'medium',
        letterSpacing: 0.5,
        fontSize: 16,
      ));
}

shadowContainer() {
  return BoxDecoration(
      boxShadow: [
        BoxShadow(
            color: (Colors.grey[200])!,
            blurRadius: 5.0,
            offset: const Offset(
              0.0,
              0.0,
            )),
      ],
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      color: Colors.white);
}

pageTitle() {
  return const TextStyle(
      color: Colors.black, fontFamily: 'semi-bold', fontSize: 20);
}

roundImage(val) {
  return BoxDecoration(
      color: Colors.grey[300],
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      image: DecorationImage(image: AssetImage('$val'), fit: BoxFit.cover));
}

bottomBorder() {
  return BoxDecoration(
      border: Border(bottom: BorderSide(width: 1, color: (Colors.grey[300])!)));
}

offContainer() {
  return const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      color: Color.fromARGB(255, 255, 185, 48));
}

offLabel() {
  return const TextStyle(color: Colors.white, fontFamily: 'medium');
}
