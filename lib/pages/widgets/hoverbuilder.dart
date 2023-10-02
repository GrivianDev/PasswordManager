import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Helpful widget builder class that returns a certain widget depending
/// on if the intern MouseRegion is hovered or not.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({required this.builder, Key? key}) : super(key: key);

  final Widget Function(bool) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) => setState(() {
        _isHovered = true;
      }),
      onExit: (PointerExitEvent event) => setState(() {
        _isHovered = false;
      }),
      child: widget.builder(_isHovered), //On _isHovered property dependend child widget
    );
  }
}
