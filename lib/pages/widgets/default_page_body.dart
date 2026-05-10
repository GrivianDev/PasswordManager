import 'package:flutter/material.dart';

class DefaultPageBody extends StatelessWidget {
  const DefaultPageBody({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox.expand(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Material( // Needed so ListTile selectedTileColor renders inside the rounded clip
            color: Theme.of(context).colorScheme.surface,
            child: child,
          ),
        ),
      ),
    );
  }
}
