import 'package:flutter/material.dart';
import 'package:runap/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:runap/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import 'package:runap/utils/constants/colors.dart';

class TPrimaryHeaderContainer extends StatelessWidget {
  const TPrimaryHeaderContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TCurvedEdgeWidget(
      child: Container(
        color: TColors.primaryColor,
        child: Stack(
          children: [
            /// -- BACKGROUND CUSTOM SHAPES
            Positioned(
              top: -150,
              right: -250,
              child: TCircleContainer(
                  backgroundColor: TColors.textWhite.withAlpha(25)),
            ),
            Positioned(
              top: 100,
              right: -300,
              child: TCircleContainer(
                  backgroundColor: TColors.textWhite.withAlpha(25)),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
