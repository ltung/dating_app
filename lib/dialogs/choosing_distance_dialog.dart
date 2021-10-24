import 'package:dating_app/dialogs/common_dialogs.dart';
import 'package:dating_app/dialogs/progress_dialog.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/screens/passport_screen.dart';
import 'package:dating_app/widgets/show_scaffold_msg.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/models/app_model.dart';
import 'package:dating_app/constants/constants.dart';

import 'package:dating_app/datas/user.dart';

import 'package:firestore_ui/firestore_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'dart:async';

import 'package:place_picker/entities/location_result.dart';

final String title = 'Setting Max. Distance';

typedef OnSnapshot = Function(DocumentSnapshot?);

class MessageListTile extends StatelessWidget {
  final int index;
  final DocumentSnapshot? document;
  final OnSnapshot? onTap;
  final User user;

  const MessageListTile({
    Key? key,
    required this.index,
    required this.document,
    required this.onTap,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String place = 'No message retrieved!';
    GeoPoint geoPoint = this.user.userGeoPoint;

    if (document != null) {
      final data = document!.data();
      if (data != null) {
        debugPrint(data.toString());
        // final receivedMessage = data['id'];
        // if (receivedMessage != null) place = receivedMessage;
        geoPoint = data['geopoint'];
        place = data['city'] + ", " + data['state'];
      }
    }

    return ListTile(
      title: Text(place),
      //subtitle: Text('${geoPoint.latitude},${geoPoint.longitude}'),
/*
      onTap: document != null && onTap != null
          ? () => onTap!.call(this.document!)
          : null,
*/
      onTap: document != null && onTap != null
          ? () => onTap!.call(this.document!)
          : null,
    );
  }
}

class MessageGridTile extends StatelessWidget {
  final int index;
  final DocumentSnapshot? document;
  final OnSnapshot? onTap;

  const MessageGridTile({
    Key? key,
    required this.index,
    required this.document,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: document != null && onTap != null
          ? () => onTap!.call(this.document!)
          : null,
      child: Container(
        color: Colors.green,
        child: Center(
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text('${this.index + 1}'),
          ),
        ),
      ),
    );
  }
}

class ChoosingDistanceDialog extends StatefulWidget {
  // Variables
  //final String flaggedUserId;
  final FirebaseFirestore firestore;
  final User user;



  //CityMaintenanceDialog({Key? key, required this.firestore, required this.user}) : super(key: key);
  ChoosingDistanceDialog({Key? key, required this.firestore, required this.user})
      : super(key: key);

  //CityMaintenanceDialog({required this.flaggedUserId});

  @override
  _ChoosingDistanceDialogState createState() => _ChoosingDistanceDialogState();
}

class _ChoosingDistanceDialogState extends State<ChoosingDistanceDialog> {
  // Variables
  final PageController _controller =
      PageController(initialPage: 0, keepPage: true);

  //final User user = this.user;

  int _currentIndex = 0;

  late AppLocalizations _i18n;
  late double _selectedMaxDistance;

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> _userSettings = UserModel().user.userSettings!;

    setState(() {
      _selectedMaxDistance = _userSettings[USER_MAX_DISTANCE].toDouble();
    });
  }

  CollectionReference get messages => widget.firestore.collection('Places');

/*
  _addMessage() => messages.doc().set(<String, dynamic>{
        'message': 'Hello world!',
        'id': widget.user.userId,
        'geopoint': widget.user.userGeoPoint,
        'city': '',
        'admin district': ''
      });
*/

  _addMessage() async {
    LocationResult? result = await Navigator.of(context).push<LocationResult?>(
        MaterialPageRoute(builder: (context) => PassportScreen()));

    //debugPrint(result.toString());

    if (result != null) {
      messages.doc().set(<String, dynamic>{
        'id': widget.user.userId,
        //'geopoint': [result.latLng!.latitude, result.latLng!.longitude],
        'geopoint': GeoPoint(result.latLng!.latitude, result.latLng!.longitude),
        'city': result.city!.name,
        'state': result.administrativeAreaLevel1!.name,
        'country': result.country!.name,
      });
    }
  }

  _removeMessage(DocumentSnapshot? snapshot) {

    if (snapshot != null) {
      //LocationResult result = snapshot.data()!['location'];
      _updateUserLocation1(
          snapshot.data()!['geopoint'],
          snapshot.data()!['city'],
          snapshot.data()!['state'],
          snapshot.data()!['country']);

      //_updateUserLocation(isPassport: true,
/*
      widget.firestore.runTransaction((transaction) async {
        transaction.delete(snapshot.reference);
      }).catchError((exception, stacktrace) {
        print("Couldn't remove item: $exception");
      });
      */
      Navigator.pop(context, true);
    }
  }

  void _updateIndex(int value) {
    if (mounted) {
      setState(() => _currentIndex = value);
      _controller.jumpToPage(_currentIndex);
    }
  }

  /// Feel free to experiment here with query parameters, upon calling `setState` or hot reloading
  /// the query will automatically update what's on the list. The easiest way to test this is to
  /// change the limit below, or remove it. The example collection has 500+ elements.
  Query get query => widget.firestore.collection('Places').limit(20);

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PageView(
        controller: _controller,
        children: <Widget>[
          Card(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            '${_i18n.translate("maximum_distance")}  km',
                            style: TextStyle(fontSize: 18)),
                        SizedBox(height: 3),
                        Text(
                            _i18n.translate(
                                "show_people_within_this_radius"),
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Slider(
                    activeColor: Theme.of(context).primaryColor,
                    value: _selectedMaxDistance,
                    label:
                    _selectedMaxDistance.round().toString() + ' km',
                    divisions: 100,
                    min: 0,

                    /// Check User VIP Account to set max distance available
                    max: UserModel().userIsVip
                        ? AppModel().appInfo.vipAccountMaxDistance
                        : AppModel().appInfo.freeAccountMaxDistance,
                    onChanged: (radius) {
                      setState(() {
                        _selectedMaxDistance = radius;
                      });
                      // debug
                      print('_selectedMaxDistance: '
                          '${radius.toStringAsFixed(2)}');
                    },
                    onChangeEnd: (radius) {
                      /// Update user max distance
                      UserModel().updateUserData(
                          userId: UserModel().user.userId,
                          data: {
                            '$USER_SETTINGS.$USER_MAX_DISTANCE':
                            double.parse(radius.toStringAsFixed(2))
                          }).then((_) {
                        print(
                            'User max distance updated -> ${radius.toStringAsFixed(2)}');
                      });
                    },
                  ),
                  // Show message for non VIP user
                  UserModel().userIsVip
                      ? Container(width: 0, height: 0)
                      : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "${_i18n.translate("need_more_radius_away")} "
                            "${AppModel().appInfo.vipAccountMaxDistance} km "
                            "${_i18n.translate('radius_away')}",
                        style: TextStyle(
                            color: Theme.of(context).primaryColor)),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Future<void> _goToPassportScreen() async {
    // Get picked location result
    LocationResult? result = await Navigator.of(context).push<LocationResult?>(
        MaterialPageRoute(builder: (context) => PassportScreen()));
    // Handle the retur result
    if (result != null) {
      // Update current your location
      _updateUserLocation(true, locationResult: result);
      // Debug info
      print(
          '_goToPassportScreen() -> result: ${result.country!.name}, ${result.city!.name}');
    } else {
      print('_goToPassportScreen() -> result: empty');
    }
  }

  Future<void> _updateUserLocation1(
      GeoPoint gp, String city, String state, String country) async {
    /// Update user location: Country & City an Geo Data
    debugPrint('def');

    /// Update user data
    await UserModel().updateUserLocation1(
        gp: gp,
        city: city,
        state: state,
        country: country,
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

  Future<void> _updateUserLocation(bool isPassport,
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
}
