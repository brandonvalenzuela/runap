import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  final userController = Get.find<UserController>();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    if (userController.isLoading.value) {
      ever(userController.isLoading, (bool loading) {
        if (!loading && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBackgroundColor = isDarkMode ? TColors.black : TColors.lightGrey;

    return Scaffold(
      backgroundColor: screenBackgroundColor,
      appBar: TAppBar(
        showBackArrow: true,
        title: Text('My profile'),
      ),

      /// -- BODY
      body: Column(
        children: [
          const SizedBox(height: TSizes.spaceBtwSections),
          _isLoading
            ? const SkeletonCircle(radius: 40)
            : TCircularImage(
                image: userController.profilePicture.isNotEmpty
                  ? userController.profilePicture
                  : TImages.userIcon,
                width: 80,
                height: 80,
                isNetworkImage: userController.profilePicture.isNotEmpty,
                backgroundColor: TColors.lightContainer,
              ),
          const SizedBox(height: TSizes.spaceBtwSections),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: TSizes.spaceBtwSections * 1.5,
                left: TSizes.defaultSpace,
                right: TSizes.defaultSpace,
                bottom: TSizes.defaultSpace
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? TColors.darkerGrey : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(TSizes.borderRadiusLg * 2),
                  topRight: Radius.circular(TSizes.borderRadiusLg * 2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 26)),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    Text(
                      'We use this data to give you personalized recommendations and calculate your daily goals',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    _isLoading
                      ? _buildSkeletonFields()
                      : _buildInfoFields(userController),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFields(UserController userController) {
    final birthdate = DateTime(1997, 6, 23);
    const height = '175 cm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoField(
          context: context,
          label: 'Full Name',
          value: userController.fullName,
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        _buildInfoField(
          context: context,
          label: 'Birthdate',
          value: DateFormat('MMM d, yyyy').format(birthdate),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        _buildInfoField(
          context: context,
          label: 'Height',
          value: height,
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        _buildGenderSelector(context),
      ],
    );
  }

  Widget _buildSkeletonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonWidget(height: 16, width: 120),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        const SkeletonWidget(height: 50, width: double.infinity, borderRadius: TSizes.cardRadiusMd),
        const SizedBox(height: TSizes.spaceBtwSections),
        const SkeletonWidget(height: 16, width: 80),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        const SkeletonWidget(height: 50, width: double.infinity, borderRadius: TSizes.cardRadiusMd),
        const SizedBox(height: TSizes.spaceBtwSections),
        const SkeletonWidget(height: 16, width: 60),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        const SkeletonWidget(height: 50, width: double.infinity, borderRadius: TSizes.cardRadiusMd),
        const SizedBox(height: TSizes.spaceBtwSections),
        const SkeletonWidget(height: 16, width: 70),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => SkeletonWidget(height: 40, width: 70, borderRadius: TSizes.cardRadiusLg)),
        ),
      ],
    );
  }

  Widget _buildInfoField({required BuildContext context, required String label, required String value}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.md),
          decoration: BoxDecoration(
            color: isDarkMode ? TColors.darkGrey.withAlpha(128) : TColors.lightContainer,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          ),
          child: Text(
            value, 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400)
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(BuildContext context) {
    final List<String> genders = ['Male', 'Female', 'Non binary', 'Prefer not to say'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
          clipBehavior: Clip.none,
          child: Row(
            children: genders.map((gender) {
              final bool isSelected = _selectedGender == gender;
              return Padding(
                padding: EdgeInsets.only(right: gender != genders.last ? TSizes.spaceBtwItems : 0),
                child: _genderOptionBox(
                  context: context,
                  label: gender,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _genderOptionBox({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color selectedColor = TColors.primaryColor;
    final Color unselectedBgColor = isDarkMode ? TColors.darkGrey : TColors.lightContainer;
    final Color unselectedTextColor = isDarkMode ? Colors.white70 : TColors.darkGrey;

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
        ),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : unselectedBgColor,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withAlpha(77),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? Colors.white : unselectedTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
