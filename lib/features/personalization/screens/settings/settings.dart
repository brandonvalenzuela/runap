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
              _buildSectionContainer(
                tileColor: tileColor,
                children: [
                  _SettingsListItem(
                    title: 'My profile',
                    onTap: () => Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft),
                    isFirst: true, // Indicar que es el primero para borde superior
                  ),
                  _buildDivider(),
                  _SettingsListItem(
                    title: 'My goals',
                    onTap: () { /* TODO: Navegar a My Goals */ },
                  ),
                   _buildDivider(),
                  _SettingsListItem(
                    title: 'Diary settings',
                    onTap: () { /* TODO: Navegar a Diary Settings */ },
                    isLast: true, // Indicar que es el último para borde inferior
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // --- SECCIÓN PARAMETERS ---
              _buildSectionHeader(context, 'Parameters'),
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildSectionContainer(
                tileColor: tileColor,
                children: [
                   _SettingsListItem(
                    title: 'My account',
                    onTap: () => Get.to(() => const AccountScreen(), transition: Transition.rightToLeft),
                    isFirst: true,
                  ),
                   _buildDivider(),
                  _SettingsListItem(
                    title: 'Manage my notifications',
                    onTap: () { /* TODO: Navegar a Notifications */ },
                  ),
                   _buildDivider(),
                  _SettingsListItem(
                    title: 'Automatic tracking apps',
                    onTap: () { /* TODO: Navegar a Tracking Apps */ },
                    isLast: true,
                  ),
                ]
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // --- SECCIÓN OTHER ---
              _buildSectionHeader(context, 'Other'),
              const SizedBox(height: TSizes.spaceBtwItems),
               _buildSectionContainer(
                 tileColor: tileColor,
                 children: [
                   _SettingsListItem(
                    title: 'Contact us',
                    onTap: () { /* TODO: Navegar a Contact Us */ },
                    isFirst: true,
                  ),
                   _buildDivider(),
                  _SettingsListItem(
                    title: 'Invite friends & get \$20', // Asegúrate de escapar el $ si es necesario
                    onTap: () { /* TODO: Implementar Invite */ },
                  ),
                  _buildDivider(),
                  _SettingsListItem(
                    title: 'Log out',
                    onTap: () => AuthenticationRepository.instance.logout(),
                  ),
                   _buildDivider(),
                   _SettingsListItem(
                    title: 'Terms of use',
                    onTap: () { /* TODO: Navegar/Mostrar Terms */ },
                  ),
                  _buildDivider(),
                   _SettingsListItem(
                    title: 'Privacy policy',
                    onTap: () { /* TODO: Navegar/Mostrar Policy */ },
                    isLast: true,
                  ),
                 ]
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

  // Construye el contenedor redondeado para un grupo de items
  Widget _buildSectionContainer({required Color tileColor, required List<Widget> children}) {
    return Material( // Usar Material para el ClipRRect
      color: tileColor,
      borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      clipBehavior: Clip.antiAlias, // Para que el Divider no se salga
      child: Column(
        children: children,
      ),
    );
  }
  
  // Construye un Divider sutil entre items
  Widget _buildDivider() {
    return const Divider(
      height: 0.5,      // Altura mínima
      thickness: 0.5,   // Grosor mínimo
      indent: TSizes.md, // Indentación izquierda
      endIndent: TSizes.md, // Indentación derecha
      // color: Colors.grey.shade300, // Color opcional
    );
  }
}

// --- WIDGET PARA LOS ITEMS DE LA LISTA ---

class _SettingsListItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? textColor; // Opcional para cambiar color de texto si es necesario
  final bool isFirst; // Para quitar borde superior del primer item
  final bool isLast; // Para quitar borde inferior del último item

  const _SettingsListItem({
    required this.title,
    required this.onTap,
    this.textColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: textColor
    );

    return InkWell( // InkWell para efecto ripple dentro del Material
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TSizes.md, 
          vertical: TSizes.lg 
        ),
        // El contenedor padre (_buildSectionContainer) ya tiene el color y borde redondeado
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: titleStyle, overflow: TextOverflow.ellipsis)
            ),
            const Icon(Iconsax.arrow_right_3, size: TSizes.iconSm, color: Colors.grey), // Icono gris
          ],
        ),
      ),
    );
  }
} 