import 'package:dating_app/datas/user.dart';
import 'package:dating_app/dialogs/flag_user_dialog.dart';
import 'package:dating_app/dialogs/city_maintenance2_dialog.dart';
import 'package:dating_app/dialogs/choosing_distance_dialog.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/plugins/swipe_stack/swipe_stack.dart';
import 'package:dating_app/widgets/badge.dart';
import 'package:dating_app/widgets/default_card_border.dart';
import 'package:dating_app/widgets/show_like_or_dislike.dart';
import 'package:dating_app/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/helpers/app_helper.dart';
import 'package:dating_app/widgets/show_scaffold_msg.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:place_picker/place_picker.dart';

import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/screens/passport_screen.dart';

class ProfileCard extends StatelessWidget {
  /// User objectuserAge
  final User user;

  /// Screen to be checked
  final String? page;

  /// Swiper position
  final SwiperPosition? position;

  ProfileCard({Key? key, this.page, this.position, required this.user})
      : super(key: key);

  // Local variables
  final AppHelper _appHelper = AppHelper();

  late AppLocalizations _i18n;

  //final FirebaseFirestore firestore;
  CollectionReference get messages =>
      FirebaseFirestore.instance.collection('Places');

  onGoBack(dynamic value) {}

  Future<void> _updateUserLocation(bool isPassport, BuildContext context,
      {LocationResult? locationResult}) async {
    /// Update user location: Country & City an Geo Data

    /// Update user data
    await UserModel().updateUserLocation(
        isPassport: isPassport,
        locationResult: locationResult,
        onSuccess: () {
          // Show success message
          showScaffoldMessage(
              context: context,
              message: _i18n.translate("location_updated_successfully"));
        },
        onFail: () {
          // Show error message
          showScaffoldMessage(
              context: context,
              message:
                  _i18n.translate("we_were_unable_to_update_your_location"));
        });
  }

  @override
  Widget build(BuildContext context) {
    // Variables
    _i18n = AppLocalizations.of(context);

    final bool requireVip =
        this.page == 'require_vip' && !UserModel().userIsVip;
    late ImageProvider userPhoto;
    // Check user vip status
    if (requireVip) {
      userPhoto = AssetImage('assets/images/crow_badge.png');
    } else {
      userPhoto = NetworkImage(user.userProfilePhoto);
    }

    //
    // Get User Birthday
    /*
    final DateTime userBirthday = DateTime(
        UserModel().user.userBirthYear,
        UserModel().user.userBirthMonth,
        UserModel().user.userBirthDay);
     */
    final DateTime userBirthday =
        DateTime(user.userBirthYear, user.userBirthMonth, user.userBirthDay);
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    // Build profile card
    return Padding(
      key: UniqueKey(),
      padding: const EdgeInsets.all(9.0),
      child: Stack(
        children: [
          /// User Card
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4.0,
            margin: EdgeInsets.all(0),
            shape: defaultCardBorder(),
            child: Container(
              decoration: BoxDecoration(
                /// User profile image
                image: DecorationImage(

                    /// Show VIP icon if user is not vip member
                    image: userPhoto,
                    fit: requireVip ? BoxFit.contain : BoxFit.cover),
              ),
              child: Container(
                /// BoxDecoration to make user info visible
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Colors.transparent
                      ]),
                ),

                /// User info container
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// User fullname
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.userFullname}, '
                              '${userAge.toString()}',
                              style: TextStyle(
                                  fontSize: this.page == 'discover' ? 20 : 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      /// User education
                      Row(
                        children: [
                          SvgIcon("assets/icons/university_icon.svg",
                              color: Colors.white, width: 20, height: 20),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.userSchool,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),

                      /// User job title
                      Row(
                        children: [
                          SvgIcon("assets/icons/job_bag_icon.svg",
                              color: Colors.white, width: 17, height: 17),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.userJobTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      this.page == 'discover'
                          ? SizedBox(height: 70)
                          : Container(width: 0, height: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Show location distance
          Positioned(
              top: 10,
              left: this.page == 'discover' ? 8 : 5,
              child: Row(children: <Widget>[
                Badge(
                    icon: this.page == 'discover'
                        ? SvgIcon("assets/icons/location_point_icon.svg",
                            color: Colors.white, width: 15, height: 15)
                        : null,
                    text:
                        '${_appHelper.getDistanceBetweenUsers(userLat: user.userGeoPoint.latitude, userLong: user.userGeoPoint.longitude)}km'),
                IconButton(
                    icon: Icon(Icons.settings_rounded,
                        color: Theme.of(context).primaryColor),
                    onPressed: () {
                      /// Change location
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return ChoosingDistanceDialog(
                                firestore: FirebaseFirestore.instance,
                                user: user);
                          }).then(onGoBack);
                    }),
/*
                IconButton(
                    icon: Icon(Icons.refresh,
                        color: Theme.of(context).primaryColor),
                    onPressed: () async {
                      /// Update user location: Country & City an Geo Data
                      _updateUserLocation(false, context);
                    }),
*/

                /// Change location
              ])),

          /// Show Like or Dislike
          this.page == 'discover'
              ? ShowLikeOrDislike(position: position!)
              : Container(width: 0, height: 0),

          /// Show message icon
          this.page == 'matches'
              ? Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: SvgIcon("assets/icons/message_icon.svg",
                          color: Colors.white, width: 30, height: 30)),
                )
              : Container(width: 0, height: 0),

          /// Show flag profile icon
          this.page == 'discover'
              ? Positioned(
                  right: 0,
                  child: Row(children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.location_city,
                            color: Theme.of(context).primaryColor),
                        onPressed: () async {
                          LocationResult? result = await Navigator.of(context)
                              .push<LocationResult?>(MaterialPageRoute(
                                  builder: (context) => PassportScreen()));

                          if (result != null) {
                            messages.doc().set(<String, dynamic>{
                              'id': user.userId,
                              //'geopoint': [result.latLng!.latitude, result.latLng!.longitude],
                              'geopoint': GeoPoint(result.latLng!.latitude,
                                  result.latLng!.longitude),
                              'city': result.city!.name,
                              'state': result.administrativeAreaLevel1!.name,
                              'country': result.country!.name,
                            });
                          }
                        }),
                    IconButton(
                        icon: Icon(Icons.list,
                            color: Theme.of(context).primaryColor),
                        onPressed: () {
                          /// Change location
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return CityMaintenance2Dialog(
                                    firestore: FirebaseFirestore.instance,
                                    user: user);
                              }).then(onGoBack);
                        }),
                    IconButton(
                        icon: Icon(Icons.flag,
                            color: Theme.of(context).primaryColor),
                        onPressed: () {
                          /// Flag user profile
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return FlagUserDialog(
                                    flaggedUserId: user.userId);
                              });
                        })
                  ]))
              : Container(width: 0, height: 0),
        ],
      ),
    );
  }
}
