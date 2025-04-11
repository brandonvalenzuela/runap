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
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    if (userController.isLoading.value) {
      ever(userController.isLoading, (bool isLoading) {
        if (!isLoading && mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(showBackArrow: true, title: Text('Mi perfil')),

      /// -- BODY
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// PROFILE PICTURE
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    _isLoading
                      ? const SkeletonCircle(radius: 40)
                      : TCircularImage(
                          image: userController.profilePicture.isEmpty
                              ? TImages.userIcon
                              : userController.profilePicture,
                          width: 80,
                          height: 80,
                          isNetworkImage: userController.profilePicture.isNotEmpty),
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

              _isLoading
                ? _buildProfileSkeleton()
                : _buildProfileInfo(userController),

              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// HEADING PERSONAL INFO
              _isLoading
                ? _buildPersonalInfoSkeleton()
                : _buildPersonalInfo(userController),
              
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              Center(
                child: _isLoading
                    ? const SkeletonWidget(height: 40, width: 150)
                    : TextButton(
                        onPressed: () {},
                        child: const Text('Cerrar cuenta',
                            style: TextStyle(color: Colors.red)),
                      ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserController userController) {
    return Column(
      children: [
        TProfileMenu(
          title: 'Nombre',
          value: userController.fullName,
          onPressed: () {}
        ),
        TProfileMenu(
          title: 'Usuario',
          value: userController.currentUser.value.username,
          onPressed: () {}
        ),
      ],
    );
  }

  Widget _buildProfileSkeleton() {
    return Column(
      children: [
        TProfileMenu(title: 'Nombre', value: '', skeleton: true, onPressed: () {}),
        TProfileMenu(title: 'Usuario', value: '', skeleton: true, onPressed: () {}),
      ],
    );
  }

  Widget _buildPersonalInfo(UserController userController) {
    return Column(
      children: [
        TProfileMenu(
          title: 'ID de usuario',
          value: userController.currentUser.value.id,
          icon: Iconsax.copy,
          onPressed: () {}
        ),
        TProfileMenu(
          title: 'Email',
          value: userController.email,
          onPressed: () {}
        ),
        TProfileMenu(
          title: 'Teléfono',
          value: userController.currentUser.value.phoneNumber,
          onPressed: () {}
        ),
        TProfileMenu(
          title: 'Género',
          value: 'Masculino',
          onPressed: () {}
        ),
        TProfileMenu(
          title: 'Fecha de nacimiento',
          value: '24 Junio, 1997',
          onPressed: () {}
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSkeleton() {
    return Column(
      children: [
        TProfileMenu(title: 'ID de usuario', value: '', icon: Iconsax.copy, skeleton: true, onPressed: () {}),
        TProfileMenu(title: 'Email', value: '', skeleton: true, onPressed: () {}),
        TProfileMenu(title: 'Teléfono', value: '', skeleton: true, onPressed: () {}),
        TProfileMenu(title: 'Género', value: '', skeleton: true, onPressed: () {}),
        TProfileMenu(title: 'Fecha de nacimiento', value: '', skeleton: true, onPressed: () {}),
      ],
    );
  }
}
