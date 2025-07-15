import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    String text = 'Weak';
    if (rating > 0.5) {
      text = 'Decent';
    }
    if (rating > 0.85) {
      text = 'Strong';
    }

    return Column(
      children: [
        Text(
          'Password strength:',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        SizedBox(
          width: 250,
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120.0,
                height: 20.0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: rating),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10.0),
                    );
                  },
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                      overflow: Theme.of(context).textTheme.displaySmall!.overflow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
