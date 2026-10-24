import 'package:flutter/material.dart';

class PreviewAvatar extends StatelessWidget {
  const PreviewAvatar(this.name, {super.key, this.radius = 14});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.black,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            color: const Color(0xFFCDBB88),
            fontSize: radius * 0.9,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class PreviewBubble extends StatelessWidget {
  const PreviewBubble({
    super.key,
    required this.text,
    required this.color,
    required this.placeholder,
  });

  final String text;
  final Color color;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final empty = text.trim().isEmpty;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        empty ? placeholder : text,
        style: TextStyle(
          color: empty ? Colors.white60 : Colors.white,
          fontSize: 12.5,
          height: 1.3,
          fontStyle: empty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}
