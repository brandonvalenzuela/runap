import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/common/widgets/texts/sections_heading.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/features/personalization/screens/profile/widget/profile_menu.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el controlador de usuario
    final userController = Get.find<UserController>();
    
    return Scaffold(
      appBar: TAppBar(showBackArrow: true, title: Text('Perfil')),

      /// -- BODY
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(() => Column(
            children: [
              /// PROFILE PICTURE
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    TCircularImage(
                        image: userController.isLoading.value || userController.profilePicture.isEmpty
                            ? TImages.userIcon
                            : userController.profilePicture,
                        width: 80,
                        height: 80,
                        isNetworkImage: userController.isLoading.value ? false : userController.profilePicture.isNotEmpty),
                    TextButton(
                        onPressed: () {},
                        child: Text('Cambiar foto de perfil')),
                  ],
                ),
              ),

              /// DETAILS
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// HEADING PROFILE INFO
              TSectionHeading(
                  title: 'Información de perfil', showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),

              TProfileMenu(
                  title: 'Nombre',
                  value: userController.isLoading.value ? 'Cargando...' : userController.fullName,
                  onPressed: () {}),
              TProfileMenu(
                  title: 'Usuario',
                  value: userController.isLoading.value ? 'Cargando...' : userController.currentUser.value.username,
                  onPressed: () {}),

              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// HEADING PERSONAL INFO
              TProfileMenu(
                  title: 'ID de usuario',
                  value: userController.isLoading.value ? 'Cargando...' : userController.currentUser.value.id,
                  icon: Iconsax.copy,
                  onPressed: () {}),
              TProfileMenu(
                  title: 'Email',
                  value: userController.isLoading.value ? 'Cargando...' : userController.email,
                  onPressed: () {}),
              TProfileMenu(
                  title: 'Teléfono',
                  value: userController.isLoading.value ? 'Cargando...' : userController.currentUser.value.phoneNumber,
                  onPressed: () {}),
              TProfileMenu(
                  title: 'Género',
                  value: 'Masculino',
                  onPressed: () {}),
              TProfileMenu(
                  title: 'Fecha de nacimiento',
                  value: '24 Junio, 1997',
                  onPressed: () {}),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Cerrar cuenta',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}
