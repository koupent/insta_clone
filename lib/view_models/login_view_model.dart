import 'package:flutter/material.dart';
import 'package:insta_clone/models/repositories/user_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final UserRepository userRepository;

  LoginViewModel({this.userRepository});

  bool isLoading = false;
  bool isSuccessful = false;

  Future<bool> isSingIn() async {
    return await userRepository.isSingIn();
  }

  Future<void> singin() async {
    isLoading = true;
    notifyListeners();

    isSuccessful = await userRepository.singIn();

    isLoading = false;
    notifyListeners();
  }
}
