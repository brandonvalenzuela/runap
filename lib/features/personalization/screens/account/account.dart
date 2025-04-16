import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart'; // Necesitamos UserController
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/popups/loaders.dart'; // Para snackbar de copiado

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<AccountScreen> {
  bool _isLoading = true;
  // Obtener UserController
  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    // Usar el isLoading del UserController si está disponible y es más fiable
    // Por ahora, mantenemos el delay simple para la UI, pero idealmente 
    // debería depender de si userController.isLoading.value es true
    if (userController.isLoading.value) {
      ever(userController.isLoading, (bool loading) {
        if (!loading && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
       // Si UserController ya cargó, no necesitamos esperar
       _isLoading = false;
    }

    // Si aún está cargando después de la verificación inicial, poner un timeout 
    // por si acaso el listener no se dispara (aunque debería con el cambio anterior)
    if (_isLoading) {
       Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _isLoading) { // Solo actualizar si todavía está cargando
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? TColors.darkerGrey : Colors.white;
    final screenBgColor = isDarkMode ? TColors.black : TColors.lightGrey;

    return Scaffold(
      backgroundColor: screenBgColor,
      // Nuevo AppBar simple
      appBar: TAppBar(
        showBackArrow: true,
        leadingOnPressed: () => Get.back(),
        title: Text('My account', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
        // backgroundColor: screenBgColor, // Opcional: si quieres que sea igual al fondo
        // elevation: 0, // Opcional: quitar sombra
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- SECCIÓN MY PROFILE ---
              Text('My profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: TSizes.sm),
              Text(
                'If you would like to modify your e-mail address, please reach out to us via the Contact button.\nWe might ask you for your User ID below.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              _isLoading
                  ? _buildSkeletonInfoField() // Esqueleto para Email
                  : _buildInfoFieldWithIcon(
                      context: context,
                      label: 'Email',
                      value: userController.email, // Dato real
                      cardColor: cardColor,
                    ),
              const SizedBox(height: TSizes.spaceBtwItems),
              _isLoading
                  ? _buildSkeletonInfoField() // Esqueleto para User ID
                  : _buildInfoFieldWithIcon(
                      context: context,
                      label: 'User ID',
                      value: userController.currentUser.value.id, // Dato real (Firebase UID)
                      cardColor: cardColor,
                      showCopyIcon: true,
                      onCopyTap: () {
                        Clipboard.setData(ClipboardData(text: userController.currentUser.value.id));
                        TLoaders.successSnackBar(title: 'Copiado', message: 'User ID copiado al portapapeles.');
                      }
                    ),
              const SizedBox(height: TSizes.spaceBtwSections),
              _isLoading
                  ? const SkeletonWidget(height: 50, width: double.infinity, borderRadius: 50)
                  : Center(
                      // Añadir ConstrainedBox para ancho mínimo
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180), // Establecer ancho mínimo
                        child: ElevatedButton(
                          onPressed: () { /* TODO: Implementar Contact Support */ },
                          style: ElevatedButton.styleFrom(
                             // Fondo más oscuro, casi negro
                            backgroundColor: TColors.colorBlack, // O un gris muy oscuro
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: TSizes.buttonHeight / 3.5, horizontal: TSizes.lg),
                            side: BorderSide.none,
                          ),
                          child: Text('Contact support', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)), // Estilo de texto explícito
                        ),
                      ),
                    ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              /// --- SECCIÓN UNITS & MEASUREMENTS ---
              Text('Units & measurements', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: TSizes.sm),
              Text(
                'Manage your height, mass and system units',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
               _isLoading
                  ? const SkeletonWidget(height: 50, width: double.infinity, borderRadius: 50)
                  : Center(
                      // Añadir ConstrainedBox para ancho mínimo
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180), // Establecer ancho mínimo
                        child: ElevatedButton(
                          onPressed: () { /* TODO: Implementar pantalla Change Units */ },
                           style: ElevatedButton.styleFrom(
                            // Fondo más oscuro, casi negro
                            backgroundColor: TColors.colorBlack, // O un gris muy oscuro
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: TSizes.buttonHeight / 3.5, horizontal: TSizes.lg),
                            side: BorderSide.none,
                          ),
                          child: Text('Change units', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)), // Estilo de texto explícito
                        ),
                      ),
                    ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              /// --- SECCIÓN MY SUBSCRIPTION ---
               Text('My subscription', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: TSizes.sm),
              Text(
                'To manage your subscription, your plan and your payment details, you have to go on Google Play Store > Profile > Payments & subscription > Subscriptions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              _isLoading
                  ? _buildSkeletonInfoField() // Esqueleto para estado de subscripción
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.md),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Text('Subscription status', style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(height: TSizes.xs),
                                // TODO: Obtener estado real de la subscripción
                                Text('Not subscribed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                             ],
                          ),
                          IconButton(onPressed: () {/* TODO: Implementar refresh status*/}, icon: const Icon(Iconsax.refresh)),
                        ],
                      )
                    ),
              const SizedBox(height: TSizes.sm),
              Align(
                alignment: Alignment.centerRight,
                child: _isLoading
                    ? const SkeletonWidget(height: 20, width: 120)
                    : TextButton(
                        onPressed: () { /* TODO: Implementar Restore Purchase */},
                        child: const Text('Restore purchase'),
                      ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // --- SECCIÓN LOGOUT --- (Ahora con título y descripción)
              Text('Delete Account', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: TSizes.sm),
              Text(
                'This action will permanently delete your account.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              _isLoading
                  ? const SkeletonWidget(height: 50, width: double.infinity) // Skeleton para el botón
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180), 
                        child: OutlinedButton(
                            onPressed: () => {},
                            style: OutlinedButton.styleFrom(
                               foregroundColor: TColors.error,
                               backgroundColor: TColors.error,
                               side: BorderSide(color: TColors.error.withAlpha(127)), // Borde de color primario semitransparente
                               padding: const EdgeInsets.symmetric(vertical: TSizes.buttonHeight / 3.5, horizontal: TSizes.lg),
                               shape: const StadiumBorder(), // Mantener forma redondeada
                            ),
                            child: Text('Delete Account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: TColors.white)), // Texto con color primario
                        ),
                      ),
                  ),
               const SizedBox(height: TSizes.spaceBtwSections), // Espacio al final
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS HELPER REUTILIZABLES PARA ESTA PANTALLA ---

  // Helper para campos de información con icono opcional (Email, User ID)
  Widget _buildInfoFieldWithIcon({
    required BuildContext context,
    required String label,
    required String value,
    required Color cardColor,
    bool showCopyIcon = false,
    VoidCallback? onCopyTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: TSizes.md, right: TSizes.sm, top: TSizes.sm, bottom: TSizes.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Para que el texto no se desborde si es muy largo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: TSizes.xs),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (showCopyIcon)
            IconButton(
              onPressed: onCopyTap,
              icon: const Icon(Iconsax.copy, size: TSizes.iconMd),
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  // Helper para los esqueletos de los campos de información
  Widget _buildSkeletonInfoField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonWidget(height: 14, width: 50), // Skeleton label
          SizedBox(height: TSizes.xs),
          SkeletonWidget(height: 18, width: 150), // Skeleton value
        ],
      ),
    );
  }

  // --- Antiguos helpers eliminados ---
  // _buildSettingsSkeletonList
  // _buildAccountSettings
  // _buildAppSettings
}
