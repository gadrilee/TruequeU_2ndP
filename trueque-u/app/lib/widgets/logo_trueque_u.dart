import 'package:flutter/material.dart';

import '../tema.dart';

class LogoTruequeU extends StatelessWidget {
  const LogoTruequeU({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: TemaTruequeU.blanco,
        borderRadius: BorderRadius.circular(Radios.r20),
      ),
      child: const Icon(
        Icons.swap_horiz,
        size: 36,
        color: TemaTruequeU.rojo,
      ),
    );
  }
}
