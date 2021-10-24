import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating_app/api/dislikes_api.dart';
import 'package:dating_app/api/likes_api.dart';
import 'package:dating_app/api/matches_api.dart';
import 'package:dating_app/api/visits_api.dart';
import 'package:dating_app/constants/constants.dart';
import 'package:dating_app/datas/user.dart';
import 'package:dating_app/dialogs/its_match_dialog.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/plugins/swipe_stack/swipe_stack.dart';
import 'package:dating_app/screens/disliked_profile_screen.dart';
import 'package:dating_app/screens/profile_screen.dart';
import 'package:dating_app/widgets/cicle_button.dart';
import 'package:dating_app/widgets/no_data2.dart';
import 'package:dating_app/widgets/processing.dart';
import 'package:dating_app/widgets/profile_card.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/api/users_api.dart';

import 'package:place_picker/place_picker.dart';
import 'package:dating_app/widgets/show_scaffold_msg.dart';

//import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

// ignore: must_be_immutable
class Discover2Tab extends StatefulWidget {
  @override
  _Discover2TabState createState() => _Discover2TabState();
}

class _Discover2TabState extends State<Discover2Tab> {
  // Variables
  final GlobalKey<SwipeStackState> _swipeKey = GlobalKey<SwipeStackState>();
  final LikesApi _likesApi = LikesApi();
  final DislikesApi _dislikesApi = DislikesApi();
  final MatchesApi _matchesApi = MatchesApi();
  final VisitsApi _visitsApi = VisitsApi();
  final UsersApi _usersApi = UsersApi();
  List<DocumentSnapshot>? _users;
  late AppLocalizations _i18n;
  bool _skip = false;

  int counter = 0;

  double val = 50;

  /// Get all Users
  Future<void> _loadUsers(List<DocumentSnapshot> dislikedUsers) async {
    _usersApi.getUsers(dislikedUsers: dislikedUsers).then((users) {
      // Check result
      if (users.isNotEmpty) {
        if (mounted) {
          setState(() => _users = users);
        }
      } else {
        if (mounted) {
          setState(() => _users = []);
        }
      }
      // Debug
      print('getUsers() -> ${users.length}');
      print('getDislikedUsers() -> ${dislikedUsers.length}');
    });
  }

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
  void initState() {
    super.initState();

    /// First: Load All Disliked Users to be filtered
    _dislikesApi
        .getDislikedUsers(withLimit: false)
        .then((List<DocumentSnapshot> dislikedUsers) async {
      /// Validate user max distance
      await UserModel().checkUserMaxDistance();

      /// Load all users
      await _loadUsers(dislikedUsers);
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    return _showUsers();
  }

  Widget _showUsers() {
    /// Check result
    if (_users == null) {
      return Processing(text: _i18n.translate("loading"));
    } else if (_users!.isEmpty) {
      /// No user found
      return NoData2(
          //user: _users,
          user: UserModel().user,
          svgName: 'search_icon',
          text: _i18n
              .translate("no_user_found_around_you_please_try_again_later"));
    } else {
      return Stack(fit: StackFit.expand, children: [
        /// User card list
        SwipeStack(
            key: _swipeKey,
            children: _users!.map((userDoc) {
              // Get User object
              final User user = User.fromDocument(userDoc.data()!);
              // Return user profile
              return SwiperItem(
                  builder: (SwiperPosition position, double progress) {
                /// Return User Card
                return ProfileCard(
                    page: 'discover', position: position, user: user);
              });
            }).toList(),
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            translationInterval: 6,
            scaleInterval: 0.03,
            stackFrom: StackFrom.None,
            onEnd: () => debugPrint("onEnd"),
            onSwipe: (int index, SwiperPosition position) {
              /// Control swipe position
              switch (position) {
                case SwiperPosition.None:
                  break;
                case SwiperPosition.Left:

                  /// Swipe Left Dislike profile
                  if (_skip) {
                    _skip = false;
                  } else
                    _dislikesApi.dislikeUser(
                        dislikedUserId: _users![index][USER_ID],
                        onDislikeResult: (r) =>
                            debugPrint('onDislikeResult: $r'));

                  break;

                case SwiperPosition.Right:

                  /// Swipe right and Like profile
                  _likeUser(context, clickedUserDoc: _users![index]);

                  break;
              }
            }),

        /// Swipe buttons
        Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Align(
                alignment: Alignment.bottomCenter,
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  refreshButton(context),
                  SizedBox(height: 10),
                  swipeButtons(context),
                ]))),

        // Vertical Slider
        Container(
            margin: const EdgeInsets.only(bottom: 20, top: 40),
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
                children: [
              SfSlider.vertical(
                min: 5,
                max: 100,
                value: val,
                interval: 20,
                showTicks: false,
                showLabels: false,
                enableTooltip: true,
                //showTooltip: true,
                minorTicksPerInterval: 1,
                onChanged: (dynamic value) {
                  setState(() {
                    val = value;
                  });
                },
              ),
            ]))
      ]);
    }
  }

  Widget refreshButton(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      cicleButton(
          bgColor: Colors.white,
          padding: 8,
          icon: Icon(Icons.refresh, size: 35, color: Colors.grey),
          onTap: () async {
            /// Update user location: Country & City an Geo Data
            //_updateUserLocation(false, context)
            _updateUserLocation(false, context);
          }),
    ]);
  }

  /// Build swipe buttons
  Widget swipeButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// Rewind profiles
        ///
        /// Go to Disliked Profiles
        /*
        cicleButton(
            bgColor: Colors.white,
            padding: 8,
            icon: Icon(Icons.restore, size: 22, color: Colors.grey),
            onTap: () {
              // Go to Disliked Profiles Screen
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DislikedProfilesScreen()));
            }),
        */
        SizedBox(width: 20),

        /// Swipe left and reject user
        cicleButton(
            bgColor: Colors.white,
            padding: 8,
            icon: Icon(Icons.close, size: 35, color: Colors.grey),
            onTap: () {
              /// Get card current index
              final cardIndex = _swipeKey.currentState!.currentIndex;

              /// Check card valid index
              if (cardIndex != -1) {
                /// Swipe left
                _swipeKey.currentState!.swipeLeft();
              }
            }),

        SizedBox(width: 20),

        /// Middle user
        cicleButton(
            bgColor: Colors.white,
            padding: 8,
            icon: Icon(Icons.navigate_next, size: 35, color: Colors.grey),
            onTap: () {
              /// Get card current index
              final cardIndex = _swipeKey.currentState!.currentIndex;
              _skip = true;

              /// Check card valid index
              if (cardIndex != -1) {
                /// Swipe left
                _swipeKey.currentState!.swipeLeft();
              }
            }),

        SizedBox(width: 20),

        /// Swipe right and like user
        cicleButton(
            bgColor: Colors.white,
            padding: 8,
            icon: Icon(Icons.favorite_border,
                size: 35, color: Theme.of(context).primaryColor),
            onTap: () async {
              /// Get card current index
              final cardIndex = _swipeKey.currentState!.currentIndex;

              /// Check card valid index
              if (cardIndex != -1) {
                /// Swipe right
                _swipeKey.currentState!.swipeRight();
              }
            }),

        SizedBox(width: 20),

        /// Go to user profile
        /*
        cicleButton(
            bgColor: Colors.white,
            padding: 8,
            icon: Icon(Icons.remove_red_eye, size: 22, color: Colors.grey),
            onTap: () {
              /// Get card current index
              final cardIndex = _swipeKey.currentState!.currentIndex;

              /// Check card valid index
              if (cardIndex != -1) {
                /// Get User object
                final User user = User.fromDocument(_users![cardIndex].data()!);

                /// Go to profile screen
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(user: user, showButtons: false)));

                /// Increment user visits an push notification
                _visitsApi.visitUserProfile(
                  visitedUserId: user.userId,
                  userDeviceToken: user.userDeviceToken,
                  nMessage: "${UserModel().user.userFullname.split(' ')[0]}, "
                      "${_i18n.translate("visited_your_profile_click_and_see")}",
                );
              }
            }),
        */
      ],
    );
  }

  /// Like user function
  Future<void> _likeUser(BuildContext context,
      {required DocumentSnapshot clickedUserDoc}) async {
    /// Check match first
    await _matchesApi.checkMatch(
        userId: clickedUserDoc[USER_ID],
        onMatchResult: (result) {
          if (result) {
            /// It`s match - show dialog to ask user to chat or continue playing
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return ItsMatchDialog(
                    swipeKey: _swipeKey,
                    matchedUser: User.fromDocument(clickedUserDoc.data()!),
                  );
                });
          }
        });

    /// like profile
    await _likesApi.likeUser(
        likedUserId: clickedUserDoc[USER_ID],
        userDeviceToken: clickedUserDoc[USER_DEVICE_TOKEN],
        nMessage: "${UserModel().user.userFullname.split(' ')[0]}, "
            "${_i18n.translate("liked_your_profile_click_and_see")}",
        onLikeResult: (result) {
          print('likeResult: $result');
        });
  }
}
