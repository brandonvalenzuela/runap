import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/features/personalization/screens/settings/settings.dart';
import 'package:runap/features/dashboard/screens/home.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    ///NO ESTA FUNCIONAND EL DARKMODE EN EL NAVMENU
    return Scaffold(
      bottomNavigationBar: Obx(
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
                icon: Icon(Iconsax.weight_1), label: 'Exercices'),
            NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
          ],
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
    //const Store(),
    //const TrainingMapScreen(),
    Container(color: Colors.blue),
    const SettingsScreen(),
  ];
}
