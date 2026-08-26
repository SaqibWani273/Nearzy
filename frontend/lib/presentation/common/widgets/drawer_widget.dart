import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utils/handle_drawer_item_tap.dart';
import '../../../constants/drawer_data.dart';
import '../../../theme/overflow_text_style.dart';

class DrawerWidget extends StatelessWidget {
  final int currentIndex;
  final BuildContext homePageContext;
  const DrawerWidget(
      {super.key, required this.currentIndex, required this.homePageContext});

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    var deviceHeight = MediaQuery.of(context).size.height;
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      width: deviceWidth * 0.7,
      child: ListView(
        // Remove padding from top
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'LocalEzy',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 40,
                fontFamily:
                    GoogleFonts.aBeeZeeTextTheme().headlineLarge?.fontFamily,
              ),
            ),
          ),
          ...menuItems.asMap().entries.map((item) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                decoration: BoxDecoration(
                  color: currentIndex == item.key
                      ? Colors.grey.shade300
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(48.0),
                ),
                child: ListTile(
                  title: Padding(
                    padding: EdgeInsets.only(left: deviceWidth * 0.07),
                    child: Text(
                      item.value.title,
                      style: overfLowTextStyle(
                          deviceWidth: deviceWidth,
                          deviceHeight: deviceHeight,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontWeight: FontWeight.w500, fontSize: 20.0)),
                    ),
                  ),
                  leading: Icon(currentIndex == item.key
                      ? item.value.selectedIcon
                      : item.value.unSelectedIcon),
                  onTap: () {
                    handleDrawerItemTap(
                      enumValue: item.value.enumValue,
                      context: context,
                      homepageContext: homePageContext,
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }
}
