import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TTrainigMenuIcon extends StatelessWidget {
  const TTrainigMenuIcon({
    super.key,
    required this.onPressed,
    required this.iconColor,
  });

  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
            onPressed: () {},
            icon: Icon(
              Iconsax.menu_1,
              color: iconColor,
            ),),
      ],
    );
  }
}
