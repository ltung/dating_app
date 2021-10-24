import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating_app/constants/constants.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class UsersApi {
  /// Get firestore instance
  ///
  final _firestore = FirebaseFirestore.instance;

  /// Get all users
  Future<List<DocumentSnapshot>> getUsers({
    required List<DocumentSnapshot> dislikedUsers,
  }) async {
    /// Build Users query
    Query usersQuery = _firestore
        .collection(C_USERS)
        .where(USER_STATUS, isEqualTo: 'active')
        .where(USER_LEVEL, isEqualTo: 'user');

    // Filter the User Gender
    usersQuery = UserModel().filterUserGender(usersQuery);

    // Instance of Geoflutterfire
    final Geoflutterfire geo = new Geoflutterfire();

    /// Get user settings
    final Map<String, dynamic>? settings = UserModel().user.userSettings;

    // // Get user geo center
    final GeoFirePoint center = geo.point(
        latitude: UserModel().user.userGeoPoint.latitude,
        longitude: UserModel().user.userGeoPoint.longitude);

    final allUsers = await geo
        .collection(collectionRef: usersQuery)
        .within(
            center: center,
            radius: settings![USER_MAX_DISTANCE].toDouble(),
            field: USER_GEO_POINT,
            strictMode: true)
        .first;

    // Remove the current user profile - If choosed to see everyone
    if (allUsers.isNotEmpty) {
      allUsers.removeWhere(
          (userDoc) => userDoc[USER_ID] == UserModel().user.userId);
    }

    /// Remove Disliked Users in list
    if (dislikedUsers.isNotEmpty) {
      dislikedUsers.forEach((dislikedUser) {
        allUsers.removeWhere(
            (userDoc) => userDoc[USER_ID] == dislikedUser[DISLIKED_USER_ID]);
      });
    }

    // Get Liked Profiles
    final List<DocumentSnapshot> likedProfiles = (await _firestore
            .collection(C_LIKES)
            .where(LIKED_BY_USER_ID, isEqualTo: UserModel().user.userId)
            .get())
        .docs;

    // Remove Liked Profiles
    if (likedProfiles.isNotEmpty) {
      likedProfiles.forEach((likedUser) {
        allUsers.removeWhere(
            (userDoc) => userDoc[USER_ID] == likedUser[LIKED_USER_ID]);
      });
    }

    /// Sort by newest
    allUsers.sort((a, b) {
      final DateTime userRegDateA = a[USER_REG_DATE].toDate();
      final DateTime userRegDateB = b[USER_REG_DATE].toDate();
      return userRegDateA.compareTo(userRegDateB);
    });

    final int minAge = settings[USER_MIN_AGE];
    final int maxAge = settings[USER_MAX_AGE];

    // Filter Profile Ages
    return allUsers.where((DocumentSnapshot user) {

    // Get User Birthday
    final DateTime userBirthday = DateTime(
      user[USER_BIRTH_YEAR],
      user[USER_BIRTH_MONTH], 
      user[USER_BIRTH_DAY]);

      /// Get user profile age to filter
      final int profileAge =
          UserModel().calculateUserAge(userBirthday);
      // Return result
      return profileAge >= minAge && profileAge <= maxAge;
    }).toList();
    
  }
}
