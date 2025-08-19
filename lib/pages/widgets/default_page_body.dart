import 'package:flutter/material.dart';

/// A reusable page root, with a rounded appbar and automatic scroll.
class DefaultPageBody extends StatelessWidget {
  const DefaultPageBody({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: child,
        ),
      ),
    );
  }
}
