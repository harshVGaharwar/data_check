import 'package:flutter/material.dart';

class StepHighlight extends AnimatedWidget {
  final Color color;
  final Widget child;

  const StepHighlight({super.key, 
    required Animation<double> animation,
    required this.color,
    required this.child,
  }) : super(listenable: animation);

  Animation<double> get _anim => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _anim.value;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: t * 0.6), width: 1.5),
        boxShadow: t > 0.1
            ? [
                BoxShadow(
                  color: color.withValues(alpha: t * 0.25),
                  blurRadius: 6,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}