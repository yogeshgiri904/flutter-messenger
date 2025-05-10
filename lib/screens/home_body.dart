
// home_body.dart
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class HomeBody extends StatelessWidget {
  final Widget screen;

  const HomeBody({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF900C3F), Color(0xFFF5B8CF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: screen,
      ),
    );
  }
}