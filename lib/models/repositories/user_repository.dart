import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:insta_clone/data_models/user.dart';
import 'package:insta_clone/models/db/database_manager.dart';
import 'package:insta_clone/utils/constants.dart';
import 'package:uuid/uuid.dart';

class UserRepository {
  final DatabaseManager dbManager;

  UserRepository({this.dbManager});

  static User currentUser;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> isSingIn() async {
    final firebaseUser = await _auth.currentUser();
    if (firebaseUser != null) {
      //ログイン履歴が残っていた場合、currentUserがnullになるのを回避
      currentUser = await dbManager.getUserInfoFromDbById(firebaseUser.uid);

      return true;
    }
    return false;
  }

  Future<bool> singIn() async {
    try {
      //Googleログインのリクエストを実行し、認証情報を取得
      GoogleSignInAccount signInAccount = await _googleSignIn.signIn();
      GoogleSignInAuthentication signInAuthentication = await signInAccount.authentication;

      //上記で取得した認証情報からFirebase認証に必要な信用状(Credential)を取得
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: signInAuthentication.idToken,
        accessToken: signInAuthentication.accessToken,
      );
      final firebaseUser = (await _auth.signInWithCredential(credential)).user;
      if (firebaseUser == null) {
        return false;
      }

      //TODO DBに登録
      final isUserExistedInDb = await dbManager.searchUserInDb(firebaseUser);
      if (!isUserExistedInDb) {
        await dbManager.insertUser(_convertToUser(firebaseUser));
      }

      currentUser = await dbManager.getUserInfoFromDbById(firebaseUser.uid);
      return true;
    } catch (error) {
      print("sign in error caught!: ${error.toString()}");
      return false;
    }
  }

  _convertToUser(FirebaseUser firebaseUser) {
    return User(
      userId: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      inAppUserName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoUrl,
      email: firebaseUser.email,
      bio: "",
    );
  }

  Future<User> getUserById(String userId) async {
    return await dbManager.getUserInfoFromDbById(userId);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut(); //パッケージのバグ有り。ほんとはdisconnect使いたい
    await _auth.signOut();
    currentUser = null;
  }

  Future<int> getNumberOfFollowers(User profileUser) async {
    return (await dbManager.getFollowerUserIds(profileUser.userId)).length;
  }

  Future<int> getNumberOfFollowings(User profileUser) async {
    return (await dbManager.getFollowingUserIds(profileUser.userId)).length;
  }

  Future<void> updateProfile(
    User profileUser,
    String nameUpdated,
    String bioUpdated,
    String photoUrlUpdated,
    bool isImageFromFile,
  ) async {
    var updatePhotoUrl;

    if (isImageFromFile) {
      final updatePhotoFile = File(photoUrlUpdated);
      final storagePath = Uuid().v1();
      updatePhotoUrl = await dbManager.uploadImageToStorage(
        updatePhotoFile,
        storagePath,
      );
    }

    final userBeforeUpdate = await dbManager.getUserInfoFromDbById(profileUser.userId);
    final updateUser = userBeforeUpdate.copyWith(
      inAppUserName: nameUpdated,
      photoUrl: isImageFromFile ? updatePhotoUrl : userBeforeUpdate.photoUrl,
      bio: bioUpdated,
    );
    await dbManager.updateProfile(updateUser);
  }

  Future<void> getCurrentUserById(String userId) async {
    currentUser = await dbManager.getUserInfoFromDbById(userId);
  }

  Future<List<User>> searchUsers(String query) async {
    return await dbManager.searchUsers(query);
  }

  Future<void> follow(User profileUser) async {
    await dbManager.follow(profileUser, currentUser);
  }

  Future<bool> checkIsFollowing(User profileUser) async {
    return await dbManager.checkIsFollowing(profileUser, currentUser);
  }

  Future<void> unFollow(User profileUser) async {
    await dbManager.unFollow(profileUser, currentUser);
  }

  Future<List<User>> getCaresMeUsers(String id, WhoCaresMeMode mode) async {
    var results = List<User>();

    switch (mode) {
      case WhoCaresMeMode.LIKE:
        final postId = id;
        results = await dbManager.getLikesUsers(postId);
        break;
      case WhoCaresMeMode.FOLLOWED:
        final profileUserId = id;
        results = await dbManager.geFollowerUsers(profileUserId);
        break;
      case WhoCaresMeMode.FOLLOWINGS:
        final profileUserId = id;
        results = await dbManager.getFollowingUsers(profileUserId);
        break;
    }

    return results;
  }
}
