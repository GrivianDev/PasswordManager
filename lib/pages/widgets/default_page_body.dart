import 'package:flutter/material.dart';

/// A reusable page root, with a rounded appbar and automatic scroll.
class DefaultPageBody extends StatelessWidget {
  const DefaultPageBody({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
