import 'dart:ui';
import 'package:flutter/material.dart';

class MorphingFab extends StatefulWidget {
  const MorphingFab({super.key, this.size, this.initialIconSize, this.toggledIconScale = 1.0, this.options = const []});

  final double? size;
  final double? initialIconSize;
  final double toggledIconScale;
  final List<FabOption> options;

  @override
  State<MorphingFab> createState() => _MorphingFabState();
}

class _MorphingFabState extends State<MorphingFab> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  bool _isOpen = false;

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _animController.forward() : _animController.reverse();
    });
  }

  Widget _buildFab() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final Color color = Color.lerp(Theme.of(context).floatingActionButtonTheme.backgroundColor, Colors.red, _animController.value)!;
          final double iconScale = lerpDouble(1, widget.toggledIconScale, _animController.value)!;

          return FloatingActionButton(
            backgroundColor: color,
            onPressed: _toggle,
            child: Transform.rotate(
              angle: _animController.value * 0.785398,
              child: Transform.scale(
                scale: iconScale,
                child: child,
              ),
            ),
          );
        },
        child: Icon(Icons.add, size: widget.initialIconSize),
      ),
    );
  }

  List<Widget> _buildOptions() {
    const totalStagger = 0.5;

    final List<Widget> optionWidgets = [];
    for (int i = 0; i < widget.options.length; i++) {
      final FabOption fabOption = widget.options[i];
      optionWidgets.add(
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final int visualIndex = widget.options.length - 1 - i;

            final double delay = (visualIndex / widget.options.length) * totalStagger;
            final double progress = ((_animController.value - delay) / (1 - totalStagger)).clamp(0.0, 1.0);
            final double curved = Curves.easeOut.transform(progress);

            return Transform.translate(
              offset: Offset((1 - curved) * 20, 0),
              child: Opacity(
                opacity: curved,
                child: Transform.scale(
                  scale: 0.8 + (curved * 0.2),
                  child: child,
                ),
              ),
            );
          },
          child: ElevatedButton.icon(
            label: Text(fabOption.label),
            icon: Icon(fabOption.icon),
            onPressed: fabOption.onPressed,
          ),
        ),
      );
    }
    return optionWidgets;
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: _animController.value < 0.01,
              child: GestureDetector(
                onTap: _isOpen ? _toggle : null,
                child: Opacity(
                  opacity: _animController.value * 0.5,
                  child: Container(color: Colors.black),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 20,
            children: [
              IgnorePointer(
                ignoring: !_isOpen,
                child: Column(
                  spacing: 10,
                  children: _buildOptions(),
                ),
              ),
              _buildFab(),
            ],
          ),
        ),
      ],
    );
  }
}

class FabOption {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  const FabOption({
    required this.onPressed,
    required this.label,
    this.icon,
  });
}
