import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:passwordmanager/pages/home_page.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';

/// Little animated Splashcreen that navigates to the [HomePage] automaticly after a few seconds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2)).then(
      (value) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 560,
                height: 120,
                child: context.read<AppState>().darkMode.value ? SvgPicture.asset('assets/darkLogo.svg') : SvgPicture.asset('assets/lightLogo.svg'),
              ),
              const Icon(
                Icons.shield_outlined,
                size: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}
