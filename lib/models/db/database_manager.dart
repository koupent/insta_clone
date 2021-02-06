import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:insta_clone/data_models/comments.dart';
import 'package:insta_clone/data_models/like.dart';
import 'package:insta_clone/data_models/post.dart';
import 'package:insta_clone/data_models/user.dart';
import 'package:insta_clone/models/repositories/user_repository.dart';

class DatabaseManager {
  final Firestore _db = Firestore.instance;

  Future<bool> searchUserInDb(FirebaseUser firebaseUser) async {
    final query = await _db.collection("users").where("userId", isEqualTo: firebaseUser.uid).getDocuments();

    if (query.documents.length > 0) {
      return true;
    }
    return false;
  }

  Future<void> insertUser(User user) async {
    await _db.collection("users").document(user.userId).setData(user.toMap());
  }

  Future<User> getUserInfoFromDbById(String userId) async {
    final query = await _db.collection("users").where("userId", isEqualTo: userId).getDocuments();
    return User.fromMap(query.documents[0].data);
  }

  Future<String> uploadImageToStorage(File imageFile, String storageId) async {
    //Storage上でのファイルの保存場所のリファレンスを取得
    final storageRef = FirebaseStorage.instance.ref().child(storageId);

    //取得したパスにファイルをアップロード
    final uploadTask = storageRef.putFile(imageFile);

    //アップロード処理完了後、ファイルのDL URLを取得
    return await (await uploadTask.onComplete).ref.getDownloadURL();
  }

  Future<void> insertPost(Post post) async {
    await _db.collection("posts").document(post.postId).setData(post.toMap());
  }

  Future<List<Post>> getPostsByUser(String userId) async {
    final query = await _db.collection("posts").getDocuments();
    if (query.documents.length == 0) return List();

    var results = List<Post>();
    await _db
        .collection("posts")
        .where("userId", isEqualTo: userId)
        .orderBy("postDateTime", descending: true)
        .getDocuments()
        .then((value) {
      value.documents.forEach((element) {
        results.add(Post.fromMap(element.data));
      });
    });
    return results;
  }

  Future<List<Post>> getPostsAndFollowings(String userId) async {
    //データ有無判定
    final query = await _db.collection("posts").getDocuments();

    //データがない場合は、空リストを返す
    if (query.documents.length == 0) return List();

    //データがある場合の処理
    //投稿データから検索キーとなるユーザーIDを取得
    var userIds = await getFollowingUserIds(userId);

    //自分自身を追加
    userIds.add(userId);

    var results = List<Post>();
    //「orderby」は並び替えメソッド。　「descending = true」は降順
    await _db
        .collection("posts")
        .where("userId", whereIn: userIds) //リスト「userIds」の中で一致するものを抽出
        .orderBy("postDateTime", descending: true) //並び替え
        .getDocuments()
        .then((value) {
      value.documents.forEach((element) {
        results.add(Post.fromMap(element.data));
      });
    });
    print("posts: $results");
    return results;
  }

  //フォローしているユーザーIDを取得
  Future<List<String>> getFollowingUserIds(String userId) async {
    //データ有無判定
    final query = await _db.collection("users").document(userId).collection("followings").getDocuments();

    //データがない場合は、空リストを返す
    if (query.documents.length == 0) return List();

    var userIds = List<String>();
    query.documents.forEach((id) {
      userIds.add(id.data["userId"]);
    });
    return userIds;
  }

  Future<List<String>> getFollowerUserIds(String userId) async {
    final query = await _db.collection("users").document(userId).collection("followers").getDocuments();
    if (query.documents.length == 0) return List();

    var userIds = List<String>();
    query.documents.forEach((id) {
      userIds.add(id.data["userId"]);
    });
    return userIds;
  }

  Future<List<User>> getLikesUsers(String postId) async {
    final query = await _db.collection("likes").where("postId", isEqualTo: postId).getDocuments();
    if (query.documents.length == 0) return List();

    var userIds = List<String>();
    query.documents.forEach((id) {
      userIds.add(id.data["likeUserId"]);
    });

    var likesUsers = List<User>();

    //非同期ループ処理
    await Future.forEach(userIds, (userId) async {
      final user = await getUserInfoFromDbById(userId);
      likesUsers.add(user);
    });
    print("誰かいいねしたね？: $likesUsers");
    return likesUsers;
  }

  Future<void> updatePost(Post updatePost) async {
    final reference = _db.collection("posts").document(updatePost.postId);
    await reference.updateData(updatePost.toMap());
  }

  Future<void> postComment(Comment comment) async {
    await _db.collection("comments").document(comment.commentId).setData(comment.toMap());
  }

  Future<List<Comment>> getComments(String postId) async {
    //データ有無判定
    final query = await _db.collection("comments").getDocuments();
    if (query.documents.length == 0) return List();
    var results = List<Comment>();
    await _db
        .collection("comments")
        .where("postId", isEqualTo: postId)
        .orderBy("commentDateTime")
        .getDocuments()
        .then((value) {
      value.documents.forEach((element) {
        results.add(Comment.fromMap(element.data));
      });
    });
    return results;
  }

  Future<void> deleteComment(String deleteCommentId) async {
    final reference = _db.collection("comments").document(deleteCommentId);
    await reference.delete();
  }

  Future<void> likeIt(Like like) async {
    await _db.collection("likes").document(like.likeId).setData(like.toMap());
  }

  Future<void> unLikeIt(Post post, User currentUser) async {
    final likeRef = await _db
        .collection("likes")
        .where("postId", isEqualTo: post.postId)
        .where("likeUserId", isEqualTo: currentUser.userId)
        .getDocuments();
    likeRef.documents.forEach((element) async {
      final ref = _db.collection("likes").document(element.documentID);
      await ref.delete();
    });
  }

  Future<List<Like>> getLikes(String postId) async {
    //データ有無確認
    final query = await _db.collection("likes").getDocuments();
    if (query.documents.length == 0) return List();
    var results = List<Like>();
    await _db
        .collection("likes")
        .where("postId", isEqualTo: postId)
        .orderBy("likeDateTime")
        .getDocuments()
        .then((value) {
      value.documents.forEach((element) {
        results.add(Like.fromMap(element.data));
      });
    });
    return results;
  }

  Future<void> deletePost(String postId, String imageStoragePath) async {
    //Post
    final postRef = _db.collection("posts").document(postId);
    await postRef.delete();

    //Comment
    final commentRef = await _db.collection("comments").where("postId", isEqualTo: postId).getDocuments();
    commentRef.documents.forEach((element) async {
      final ref = _db.collection("comments").document(element.documentID);
      await ref.delete();
    });

    //Likes
    final likeRef = await _db.collection("likes").where("postId", isEqualTo: postId).getDocuments();
    likeRef.documents.forEach((element) async {
      final ref = _db.collection("likes").document(element.documentID);
      await ref.delete();
    });

    //Storage
    final storageRef = FirebaseStorage.instance.ref().child(imageStoragePath);
    storageRef.delete();
  }

  Future<void> updateProfile(User updateUser) async {
    final reference = _db.collection("users").document(updateUser.userId);
    await reference.updateData(updateUser.toMap());
  }

  Future<List<User>> searchUsers(String queryString) async {
    final query = await _db
        .collection("users")
        .orderBy("inAppUserName")
        .startAt([queryString]).endAt([queryString + "\uf8ff"]).getDocuments();

    if (query.documents.length == 0) return List();

    var soughtUsers = List<User>();
    query.documents.forEach((element) {
      final selectedUser = User.fromMap(element.data);
      if (selectedUser.userId != UserRepository.currentUser.userId) {
        soughtUsers.add(selectedUser);
      }
    });

    return soughtUsers;
  }

  Future<bool> checkIsFollowing(User profileUser, User currentUser) async {
    final query = await _db.collection("users").document(currentUser.userId).collection("followings").getDocuments();
    if (query.documents.length == 0) return false;

    final checkQuery = await _db
        .collection("users")
        .document(currentUser.userId)
        .collection("followings")
        .where("userId", isEqualTo: profileUser.userId)
        .getDocuments();

    if (checkQuery.documents.length > 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> follow(User profileUser, User currentUser) async {
    //CurrentUserにとってのfollowingは
    await _db
        .collection("users")
        .document(currentUser.userId)
        .collection("followings")
        .document(profileUser.userId)
        .setData({"userId": profileUser.userId});

    //profileUserにとってのfollowers
    await _db
        .collection("users")
        .document(profileUser.userId)
        .collection("followers")
        .document(currentUser.userId)
        .setData({"userId": currentUser.userId});
  }

  Future<void> unFollow(User profileUser, User currentUser) async {
    //CurrentUserのfollowingからの削除
    await _db
        .collection("users")
        .document(currentUser.userId)
        .collection("followings")
        .document(profileUser.userId)
        .delete();

    //ProfileUserのfollowersからの削除
    await _db
        .collection("users")
        .document(profileUser.userId)
        .collection("followers")
        .document(currentUser.userId)
        .delete();
  }

  Future<List<User>> geFollowerUsers(String profileUserId) async {
    final followerUserIds = await getFollowingUserIds(profileUserId);
    var followerUsers = List<User>();
    await Future.forEach(followerUserIds, (followerUserId) async {
      final user = await getUserInfoFromDbById(followerUserId);
      followerUsers.add(user);
    });
    return followerUsers;
  }

  Future<List<User>> getFollowingUsers(String profileUserId) async {
    final followingUserIds = await getFollowingUserIds(profileUserId);
    var followingUsers = List<User>();
    await Future.forEach(followingUserIds, (followingUserId) async {
      final user = await getUserInfoFromDbById(followingUserId);
      followingUsers.add(user);
    });
    return followingUsers;
  }
}
