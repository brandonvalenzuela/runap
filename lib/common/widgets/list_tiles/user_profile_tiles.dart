import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
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
    return ListTile(
      leading: const TCircularImage(
          image: TImages.userIcon, width: 50, height: 50, padding: 0),
      title: Text('Brandon Valenzuela',
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .apply(color: TColors.black)),
      subtitle: Text('brandonvalenzual@gmail.com',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .apply(color: TColors.black)),
      trailing: IconButton(
          onPressed: onPressed,
          icon: const Icon(Iconsax.edit, color: TColors.black)),
    );
  }
}
