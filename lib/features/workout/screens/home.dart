import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/brands/brand_show_case.dart';
import 'package:runap/common/widgets/texts/sections_heading.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: Row(
          // 1. Row como base del title (análogo horizontal de ListTile)
          children: <Widget>[
            Padding(
              // 2. `leading` (imagen) con CircleAvatar
              padding: const EdgeInsets.only(right: TSizes.spaceBtwItems),
              child: CircleAvatar(
                backgroundImage: AssetImage(TImages.userIcon),
                radius: 25,
              ),
            ),
            Column(
              // 3. Column para title y subtitle (análogo vertical de ListTile)
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  //  `title` (Username)
                  'Brandon Valenzuela',
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  // `subtitle` (Email/Username)
                  'brandonvalenzuela@gmail.com',
                  style: TextStyle(color: TColors.darkGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Get.to(() => const ProfileScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          /// HEADER - Sección Fija Superior
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TColors.darkGrey),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_run,
                          color: TColors.primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summer challenge 🔥',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '5km marathon',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Iconsax.arrow_right),
                    ],
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                child: Divider(),
              ),
              // TSectionHeading ahora está fuera del área scrolleable
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                child: TSectionHeading(
                  title: 'Workouts of the week',
                  onPressed: () => Get.to(() => MapScreen() /*MapScreen()*/),
                ),
              ),
            ],
          ),

          /// BODY - Sección Scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace,
                  vertical: TSizes.spaceBtwItems),
              child: Column(
                children: [
                  TBrandShowcase(images: [
                    TImages.jacketIcon,
                    TImages.shirtIcon,
                    TImages.tshirtIcon
                  ]),
                  TBrandShowcase(images: [
                    TImages.jacketIcon,
                    TImages.shirtIcon,
                    TImages.tshirtIcon
                  ]),
                  TBrandShowcase(images: [
                    TImages.jacketIcon,
                    TImages.shirtIcon,
                    TImages.tshirtIcon
                  ]),
                  // TGridLayout(
                  //   itemCount: 6,
                  //   itemBuilder: (_, index) => const TWorkoutCardVertical(),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
