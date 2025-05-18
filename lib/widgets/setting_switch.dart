import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class SettingSwitch extends StatelessWidget {
  final bool value;
  final String activeText;
  final String inactiveText;
  final ValueChanged<bool> onToggle;

  const SettingSwitch({
    required this.value,
    required this.activeText,
    required this.inactiveText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      value: value,
      width: 104.0,
      height: 47.0,
      borderRadius: 50.0,
      valueFontSize: 25.0,
      switchBorder: const Border(
        top: BorderSide(color: Color(0xFF364E65), width: 2),
        right: BorderSide(color: Color(0xFF364E65), width: 2),
        bottom: BorderSide(color: Color(0xFF364E65), width: 2),
        left: BorderSide(color: Color(0xFF364E65), width: 2),
      ),
      activeText: activeText,
      activeTextColor: Colors.white,
      activeColor: const Color(0xFF0072BC),
      inactiveText: inactiveText,
      inactiveTextColor: const Color(0xFF0072BC),
      inactiveColor: Colors.white,
      inactiveToggleColor: const Color(0xFF0072BC),
      showOnOff: true,
      toggleSize: 37.0,
      onToggle: onToggle,
    );
  }
}