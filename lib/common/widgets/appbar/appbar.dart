import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/device/device_utility.dart';
import 'package:runap/utils/helpers/page_transitions.dart';

class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar(
      {super.key,
      this.title,
      this.showBackArrow = false,
      this.leadingIcon,
      this.actions,
      this.leadingOnPressed,
      this.elevation = 0});

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final int elevation;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
        child: AppBar(
          automaticallyImplyLeading: false,
          leading: showBackArrow
              ? IconButton(
                  onPressed: () => _handleBackButtonPress(context),
                  icon: const Icon(Iconsax.arrow_left))
              : leadingIcon != null
                  ? IconButton(
                      onPressed: leadingOnPressed, icon: Icon(leadingIcon))
                  : null,
          title: title,
          centerTitle: true,
          actions: actions,
        ));
  }

  /// Método personalizado para manejar la acción del botón de retroceso
  void _handleBackButtonPress(BuildContext context) {
    // Usar nuestro sistema de transiciones personalizado
    TPageTransitions.back();
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(TDiviceUtility.getAppBarHeight() - elevation.toDouble());
}
