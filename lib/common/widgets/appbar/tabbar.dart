import 'package:flutter/material.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class TTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// IF YOU WANT TO ADD THE BACKGROUND COLOR TO TABS YOU HAVE TO WRAP THEM IN MATERIAL WIDGET.
  /// TO DO THAT WE NEED [PreferredSized] WIDGET AND THAT'S WHY CREATED CUSTOM CLASS [PreferredSizeWidget]
  const TTabBar({
    super.key,
    required this.tabs,
  });

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Material(
        color: dark ? TColors.dark : TColors.white,
        child: TabBar(
          tabs: tabs,
          isScrollable: false,
          indicatorColor: TColors.primaryColor,
          labelColor: dark ? TColors.white : TColors.primaryColor,
          unselectedLabelColor: TColors.darkGrey,
        ));
  }

  @override
  Size get preferredSize => Size.fromHeight(0);
}
