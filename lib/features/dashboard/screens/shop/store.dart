import 'package:flutter/material.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/appbar/tabbar.dart';
import 'package:runap/common/widgets/workouts/menu/workout_menu_icon.dart';
import 'package:runap/features/dashboard/screens/shop/widget/category_tab.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class Store extends StatelessWidget {
  const Store({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 7,
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

                  /// -- TABS
                  bottom: const TTabBar(
                    tabs: [
                      Tab(child: Text('Mon')),
                      Tab(child: Text('Tue')),
                      Tab(child: Text('Wed')),
                      Tab(child: Text('Thu')),
                      Tab(child: Text('Fri')),
                      Tab(child: Text('Sat')),
                      Tab(child: Text('Sun')),
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
