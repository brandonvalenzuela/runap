import 'package:flutter/material.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/appbar/tabbar.dart';
import 'package:runap/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:runap/common/widgets/layouts/grid_layout.dart';
import 'package:runap/common/widgets/texts/sections_heading.dart';
import 'package:runap/common/widgets/training/training_card.dart';
import 'package:runap/common/widgets/workouts/menu/workout_menu_icon.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/dashboard/screens/shop/widget/category_tab.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class Store extends StatelessWidget {
  const Store({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 5,
        child: Scaffold(
          /// APPBAR
          appBar: TAppBar(
            title: Text('Store',
                style: Theme.of(context).textTheme.headlineMedium),
            actions: [
              TTrainigMenuIcon(onPressed: () {}, iconColor: TColors.black)
            ],
          ),
          body: NestedScrollView(
            /// -- HEADER --
            headerSliverBuilder: (_, innerBoxIsScrollabled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  floating: true,
                  backgroundColor: THelperFunctions.isDarkMode(context)
                      ? TColors.black
                      : TColors.white,
                  expandedHeight: 440,
                  flexibleSpace: Padding(
                    padding: EdgeInsets.all(TSizes.defaultSpace),
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        /// -- SEARCH BAR
                        SizedBox(height: TSizes.spaceBtwItems),
                        TSearchContainer(
                            text: 'Search in Store',
                            showBorder: false,
                            showBackground: false,
                            padding: EdgeInsets.zero),
                        SizedBox(height: TSizes.spaceBtwSections),

                        /// -- FEATURE BRANDS
                        TSectionHeading(
                            title: 'Feature Brands', onPressed: () {}),
                        SizedBox(height: TSizes.spaceBtwItems / 1.5),

                        /// -- BRANDS GRID
                        TGridLayout(
                          itemCount: 4,
                          mainAxisExtent: 80,
                          itemBuilder: (_, index) {
                            return TrainingCard(
                              showBorder: false,
                              session: Session(
                                sessionDate: DateTime.now(),
                                workoutName: 'Brand ${index + 1}',
                                description: 'Description ${index + 1}',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  /// -- TABS
                  bottom: const TTabBar(
                    tabs: [
                      Tab(child: Text('Sports')),
                      Tab(child: Text('Furniture')),
                      Tab(child: Text('Electronics')),
                      Tab(child: Text('Clothes')),
                      Tab(child: Text('Cosmetics')),
                    ],
                  ),
                ),
              ];
            },

            /// -- BODY
            body: const TabBarView(
              children: [
                TCategoryTab(),
                TCategoryTab(),
                TCategoryTab(),
                TCategoryTab(),
                TCategoryTab()
              ],
            ),
          ),
        ));
  }
}
