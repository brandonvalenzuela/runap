import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/appbar/appbar.dart'; // Asumiendo que TAppBar existe
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/features/personalization/screens/account/account.dart'; // Para navegar a Account
import 'package:runap/features/personalization/screens/profile/profile.dart'; // Para navegar a Profile
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
// Importar Package Info Plus si se usa para la versión
// import 'package:package_info_plus/package_info_plus.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // --- Opcional: Método para obtener la versión de la app ---
  // Future<String> _getAppVersion() async {
  //   try {
  //     PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //     return 'Version v${packageInfo.version} - ${packageInfo.buildNumber}';
  //   } catch (e) {
  //     return 'Version unknown';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? TColors.black : TColors.lightGrey;
    final tileColor = isDarkMode ? TColors.darkerGrey : Colors.white;
    final userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: TAppBar(
        leadingIcon: Iconsax.close_square,
        leadingOnPressed: () => Get.back(),
        title: Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace), // Padding horizontal principal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: TSizes.spaceBtwSections / 2), // Espacio inicial reducido

              // --- SECCIÓN MY PROFILE ---
              _buildSectionHeader(context, 'My profile'),
              const SizedBox(height: TSizes.spaceBtwItems),
              _SettingsListItem(
                title: 'My profile',
                tileColor: tileColor,
                onTap: () => Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft),
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'My goals',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar a My Goals */ },
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Diary settings',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar a Diary Settings */ },
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // --- SECCIÓN PARAMETERS ---
              _buildSectionHeader(context, 'Parameters'),
              const SizedBox(height: TSizes.spaceBtwItems),
              _SettingsListItem(
                title: 'My account',
                tileColor: tileColor,
                onTap: () => Get.to(() => const AccountScreen(), transition: Transition.rightToLeft),
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Manage my notifications',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar a Notifications */ },
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Automatic tracking apps',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar a Tracking Apps */ },
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // --- SECCIÓN OTHER ---
              _buildSectionHeader(context, 'Other'),
              const SizedBox(height: TSizes.spaceBtwItems),
              _SettingsListItem(
                title: 'Contact us',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar a Contact Us */ },
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Invite friends & get \$20',
                tileColor: tileColor,
                onTap: () { /* TODO: Implementar Invite */ },
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Log out',
                tileColor: tileColor,
                onTap: () => AuthenticationRepository.instance.logout(),
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Terms of use',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar/Mostrar Terms */ },
              ),
              const SizedBox(height: TSizes.sm),
              _SettingsListItem(
                title: 'Privacy policy',
                tileColor: tileColor,
                onTap: () { /* TODO: Navegar/Mostrar Policy */ },
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // --- FOOTER (Version & User ID) ---
              Center(
                child: Column(
                  children: [
                    // --- Usar FutureBuilder para la versión (opcional) ---
                    // FutureBuilder<String>(
                    //   future: _getAppVersion(),
                    //   builder: (context, snapshot) {
                    //     return Text(snapshot.data ?? 'Loading version...', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey));
                    //   }
                    // ),
                     Text('Version v1.0.0 - 4120', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey)), // Placeholder por ahora
                    Obx(() => Text(
                      // No mostrar User ID si aún está cargando o es nulo/vacío
                      userController.isLoading.value || userController.currentUser.value.id.isEmpty 
                        ? 'User ID: Loading...'
                        : 'User ID: ${userController.currentUser.value.id}', 
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey))
                    ),
                  ],
                ),
              ),
               const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // Construye el título de una sección
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

// --- WIDGET PARA LOS ITEMS DE LA LISTA (Modificado) ---

class _SettingsListItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color tileColor; // Ahora requerido
  final Color? textColor;

  const _SettingsListItem({
    required this.title,
    required this.onTap,
    required this.tileColor, // Añadido
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: textColor
    );

    // Aplicar Material y borderRadius aquí
    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TSizes.md, 
            vertical: TSizes.lg 
          ),
          // El Material padre ahora maneja color y borderRadius
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: titleStyle, overflow: TextOverflow.ellipsis)
              ),
              const Icon(Iconsax.arrow_right_3, size: TSizes.iconSm, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
} 