import 'package:dating_app/dialogs/city_maintenance_dialog.dart';
import 'package:dating_app/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:dating_app/datas/user.dart';


class NoData2 extends StatelessWidget {
  // Variables
  final String? svgName;
  final Widget? icon;
  final String text;

  final User user;

  const NoData2({this.svgName, this.icon, required this.text, required this.user});

  @override
  Widget build(BuildContext context) {
    // Handle icon
    late Widget _icon;
    // Check svgName
    if (svgName != null) {
      // Get SVG icon
      _icon = SvgIcon("assets/icons/$svgName.svg",
          width: 100, height: 100, color: Theme.of(context).primaryColor);
    } else {
      _icon = icon!;
    }

    return Column(children: <Widget>[
      IconButton(
          icon: Icon(Icons.location_city,
              color: Theme.of(context).primaryColor),
          onPressed: () {
            /// Change location
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return CityMaintenanceDialog(
                      firestore: FirebaseFirestore.instance, user: user);
                });
          }),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Show icon
            _icon,
            Text(text,
                style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
          ],
        ),
      )
    ]);
  }
}
