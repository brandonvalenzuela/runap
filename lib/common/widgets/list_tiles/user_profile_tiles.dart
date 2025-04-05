import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';

class TUserPorfileTile extends StatelessWidget {
  const TUserPorfileTile({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();
    return ListTile(
      leading: Obx(() => controller.isLoading.value
          ? const SkeletonCircle(radius: 25)
          : TCircularImage(
              image: controller.profilePicture.isEmpty
                  ? TImages.userIcon
                  : controller.profilePicture,
              width: 50,
              height: 50,
              padding: 0,
              isNetworkImage: controller.profilePicture.isNotEmpty,
            )
          ),
      title: Obx(() => controller.isLoading.value
          ? const SkeletonWidget(height: 16, width: 150)
          : Text(controller.fullName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .apply(color: TColors.colorBlack))
          ),
      subtitle: Obx(() => controller.isLoading.value
          ? const SkeletonWidget(height: 12, width: 200)
          : Text(controller.email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .apply(color: TColors.colorBlack))
          ),
      trailing: controller.isLoading.value
          ? const SkeletonWidget(height: 24, width: 24) // Placeholder for icon
          : IconButton(
              onPressed: onPressed,
              icon: const Icon(Iconsax.edit, color: TColors.colorBlack)),
    );
  }
}
