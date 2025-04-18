import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/notification/notification_controller.dart';
import 'package:runap/features/dashboard/presentation/pages/calendar/calendar.dart';
import 'package:runap/features/dashboard/presentation/pages/home.dart';
import 'package:runap/features/gamification/presentation/screens/gamification_profile_screen.dart';
import 'package:runap/features/progress/progress.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/constants/text_strings.dart';
import 'package:runap/utils/device/device_utility.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationController = Get.put(NavigationController());
    final notificationController = Get.put(NotificationController());
    final darkMode = THelperFunctions.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double dotSize = 6.0;
    final double bottomPadding = 6.0;
    final int destinationCount = 4;
    final double slotWidth = screenWidth / destinationCount;
    final containerHeight = 70 + bottomPadding + dotSize;
    final unselectedIconColor = darkMode ? TColors.lightGrey : TColors.darkGrey;
    final selectedIconColor = TColors.primaryColor;

    return Scaffold(
      bottomNavigationBar: Container(
        height: containerHeight,
        decoration: BoxDecoration(
          color: darkMode ? TColors.colorBlack : Colors.white,
          boxShadow: [
            BoxShadow(
              color: darkMode ? Colors.black38 : Colors.grey.withAlpha(51),
              spreadRadius: 0.5,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Obx(() {
          final double dotLeftPosition =
              (navigationController.selectedIndex.value * slotWidth) +
                  (slotWidth / 2) -
                  (dotSize / 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              NavigationBar(
                height: 70,
                elevation: 0,
                selectedIndex: navigationController.selectedIndex.value,
                onDestinationSelected: (index) {
                  navigationController.selectedIndex.value = index;
                  TDiviceUtility.vibrateMedium();
                },
                backgroundColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Iconsax.home,
                      color: unselectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    selectedIcon: Icon(
                      Iconsax.home,
                      color: selectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Iconsax.calendar,
                      color: unselectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    selectedIcon: Icon(
                      Iconsax.calendar,
                      color: selectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Iconsax.clipboard_text,
                      color: unselectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    selectedIcon: Icon(
                      Iconsax.clipboard_text,
                      color: selectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    label: 'JOURNAL',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Iconsax.medal,
                      color: unselectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    selectedIcon: Icon(
                      Iconsax.medal,
                      color: selectedIconColor,
                      size: TSizes.iconLg,
                    ),
                    label: 'Progreso',
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: dotLeftPosition,
                bottom: systemBottomPadding + bottomPadding,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: selectedIconColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      body: Stack(
        children: [
          Obx(() => navigationController
              .screens[navigationController.selectedIndex.value]),
          Obx(() {
            final isVisible = notificationController.isVisible.value;
            final message = notificationController.message.value;
            final type = notificationController.notificationType.value;

            // Simplificar mensaje si es muy largo
            final String displayMessage = _simplifyMessage(message);

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              bottom: isVisible ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                color: type.color,
                padding: EdgeInsets.symmetric(
                  horizontal: TSizes.lg,
                  vertical: TSizes.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconForNotificationType(type),
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: TSizes.sm),
                    Expanded(
                      child: Text(
                        displayMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Método para simplificar mensajes largos
  String _simplifyMessage(String message) {
    // Simplificar mensajes específicos usando las constantes de TTexts
    if (message == TTexts.noInternet) {
      return TTexts.noInternetShort;
    } else if (message == TTexts.connectionRestored) {
      return TTexts.connectionRestoredShort;
    } else if (message.contains(TTexts.checkInput)) {
      return TTexts.error;
    } else if (message.contains(TTexts.emailNotVerified)) {
      return TTexts.verificationPending;
    } else if (message.contains(TTexts.checkEmailToVerify)) {
      return TTexts.emailSent;
    }

    // Si el mensaje es muy largo (más de 30 caracteres), acortarlo
    if (message.length > 30) {
      // Intentar usar versiones cortas de mensajes comunes
      final words = message.split(' ');
      String simplified = '';

      // Mantener solo las palabras importantes del mensaje
      for (int i = 0; i < words.length; i++) {
        // Saltar palabras "a", "de", "en", "por", "y", "el", "la", etc.
        if ((words[i].length <= 2 || _isCommonPreposition(words[i])) && i > 0)
          continue;

        simplified += '${simplified.isEmpty ? '' : ' '}${words[i]}';

        // Si ya tenemos suficientes palabras, parar
        if (simplified.length > 25) break;
      }

      return simplified;
    }

    return message;
  }

  // Ayuda a identificar preposiciones y artículos comunes en español
  bool _isCommonPreposition(String word) {
    const common = [
      'de',
      'del',
      'el',
      'la',
      'los',
      'las',
      'por',
      'para',
      'con',
      'sin',
      'en',
      'entre',
      'hacia',
      'hasta',
      'desde',
      'sobre',
      'tras',
      'y',
      'e',
      'o',
      'u'
    ];
    return common.contains(word.toLowerCase());
  }

  IconData _getIconForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Iconsax.tick_circle;
      case NotificationType.error:
        return Iconsax.info_circle;
      case NotificationType.warning:
        return Iconsax.warning_2;
      case NotificationType.connectivity:
        return Iconsax.wifi;
      case NotificationType.info:
      default:
        return Iconsax.message;
    }
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const ProgressScreen(),
    const GamificationProfileScreen(),
  ];
}
