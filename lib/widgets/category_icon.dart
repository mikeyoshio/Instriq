import 'package:flutter/material.dart';

import '../models/instrument.dart';

IconData iconForKey(String key) {
  switch (key) {
    case 'cut':
      return Icons.content_cut;
    case 'pinch':
      return Icons.back_hand;
    case 'needle':
      return Icons.push_pin;
    case 'expand':
      return Icons.open_in_full;
    case 'suction':
      return Icons.air;
    case 'bolt':
      return Icons.bolt;
    case 'tool':
    default:
      return Icons.build;
  }
}

Color colorForCategory(InstrumentCategory category) {
  switch (category) {
    case InstrumentCategory.corte:
      return Colors.redAccent;
    case InstrumentCategory.diseccion:
      return Colors.deepPurpleAccent;
    case InstrumentCategory.sutura:
      return Colors.teal;
    case InstrumentCategory.separacion:
      return Colors.orangeAccent;
    case InstrumentCategory.succion:
      return Colors.blueAccent;
    case InstrumentCategory.especiales:
      return Colors.green;
  }
}

class InstrumentIcon extends StatelessWidget {
  final String iconKey;
  final InstrumentCategory category;
  final double size;

  const InstrumentIcon({
    super.key,
    required this.iconKey,
    required this.category,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(iconForKey(iconKey), color: color, size: size * 0.55),
    );
  }
}
