import 'package:ethercrypt/pages/widgets/default_page_body.dart';
import 'package:flutter/material.dart';

class SettingsTabPage extends StatefulWidget {
  const SettingsTabPage({
    super.key,
    required this.layoutBreakpoint,
    required this.title,
    required this.child,
  });

  final double layoutBreakpoint;
  final String title;
  final Widget child;

  @override
  State<SettingsTabPage> createState() => _SettingsTabPageState();
}

class _SettingsTabPageState extends State<SettingsTabPage> {
  bool _didPop = false;

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > widget.layoutBreakpoint;

    if (isWide && !_didPop) {
      _didPop = true; // Guard against double pops

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: DefaultPageBody(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
