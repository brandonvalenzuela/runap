import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:runap/common/widgets/custom_shapes/containers/skeleton_primary_header_container.dart';
import 'package:runap/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:runap/common/widgets/list_tiles/skeleton_settings_menu_tile.dart';
import 'package:runap/common/widgets/list_tiles/user_profile_tiles.dart';
import 'package:runap/common/widgets/texts/sections_heading.dart';
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simular carga con 1.5 segundos
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- HEADER
            _isLoading 
              ? const SkeletonPrimaryHeader() // Mostrar esqueleto del header
              : TPrimaryHeaderContainer( // Mostrar header real
                  child: Column(
                    children: [
                      TAppBar(
                          title: Text('Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .apply(color: TColors.white))),
                      TUserPorfileTile(
                          onPressed: () => Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft)),
                      const SizedBox(height: TSizes.spaceBtwSections),
                    ],
                  ),
                ),

            /// -- BODY
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// ACCOUNT SETTINGS
                  TSectionHeading(
                    title: 'Account Settings',
                    showActionButton: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  _isLoading ? _buildSettingsSkeletonList(7) : _buildAccountSettings(),

                  /// -- APP SETTINGS
                  const SizedBox(height: TSizes.spaceBtwSections),
                  TSectionHeading(
                      title: 'App Settings', showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  _isLoading ? _buildSettingsSkeletonList(4) : _buildAppSettings(),

                  /// -- LOGOUT BUTTON
                  const SizedBox(height: TSizes.spaceBtwSections),
                  _isLoading
                      ? const SkeletonWidget(height: 50, width: double.infinity) // Skeleton for button
                      : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                              onPressed: () =>
                                  AuthenticationRepository.instance.logout(),
                              child: const Text('Logout')),
                        ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para construir la lista de esqueletos
  Widget _buildSettingsSkeletonList(int count) {
    return Column(
      children: List.generate(count, (_) => const SkeletonSettingsMenuTile()),
    );
  }

  // Helper para construir las opciones reales de cuenta
  Widget _buildAccountSettings() {
    return Column(
      children: [
        TSettingsMenuTile(
            icon: Iconsax.safe_home,
            title: 'My Addresses',
            subTitle: 'Set shopping delivery addresses',
            onTap: () {}),
        TSettingsMenuTile(
            icon: Iconsax.shopping_cart,
            title: 'My Cart',
            subTitle: 'Add, remove products and move to checkout',
            onTap: () {}),
        TSettingsMenuTile(
            icon: Iconsax.bag_tick,
            title: 'My Orders',
            subTitle: 'In-progress and completed orders',
            onTap: () {}),
        TSettingsMenuTile(
            icon: Iconsax.bank,
            title: 'Bank Account',
            subTitle: 'Withdraw balance to registered bank account',
            onTap: () {}),
        TSettingsMenuTile(
            icon: Iconsax.discount_shape,
            title: 'My Coupons',
            subTitle: 'List of all the discounted coupons',
            onTap: () {}),
        TSettingsMenuTile(
            icon: Iconsax.notification,
            title: 'Notifications',
            subTitle: 'Set any kind of notification message',
            onTap: () {}),
        TSettingsMenuTile(
            icon: Iconsax.security_card,
            title: 'Account Privacy',
            subTitle: 'Manage data usage and connected accounts',
            onTap: () {}),
      ],
    );
  }

  // Helper para construir las opciones reales de app
  Widget _buildAppSettings() {
    return Column(
      children: [
         TSettingsMenuTile(
            icon: Iconsax.document_upload,
            title: 'Load Data',
            subTitle: 'Upload Data to your Cloud Firebase',
            onTap: () {}),
        TSettingsMenuTile(
          icon: Iconsax.location,
          title: 'Geolocation',
          subTitle: 'Set recommendations based on location',
          trailing: Switch(value: true, onChanged: (value) {}),
        ),
        TSettingsMenuTile(
          icon: Iconsax.security_user,
          title: 'Safe Mode',
          subTitle: 'Search result is safe for all ages',
          trailing: Switch(value: false, onChanged: (value) {}),
        ),
        TSettingsMenuTile(
          icon: Iconsax.image,
          title: 'HD Image Quality',
          subTitle: 'Set image quality to be seen',
          trailing: Switch(value: false, onChanged: (value) {}),
        ),
      ],
    );
  }
}
