import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget child;
  const Responsive({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth:
              600, //this shows that waht we rap with responsive widget they cannot exceed size of 600
        ),
        child: child,
      ),
    );
  }
}
