import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/features/dashboard/screens/calendar/calendar.dart';
import 'package:runap/features/personalization/screens/settings/settings.dart';
import 'package:runap/features/dashboard/screens/home.dart';
import 'package:runap/tests/report_screen.dart';
import 'package:runap/tests/widgets/Test1.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: darkMode ? Colors.black38 : Colors.grey.withAlpha(51),
              spreadRadius: 0.5,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Obx(
          () => NavigationBar(
            height: 60,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            backgroundColor: darkMode ? TColors.black : Colors.white,
            indicatorColor: darkMode
                ? TColors.white.withAlpha(25)
                : TColors.black.withAlpha(25),
            destinations: const [
              NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Iconsax.calendar), label: 'Calendar'),
              NavigationDestination(icon: Icon(Iconsax.cake), label: 'Test1'),
              NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
              NavigationDestination(
                  icon: Icon(Icons.storage), label: 'LocalStorage'),
            ],
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const Test1(),
    const SettingsScreen(),
    DebugScreen(),
  ];
}
