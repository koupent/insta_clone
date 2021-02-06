import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:insta_clone/di/providers.dart';
import 'package:insta_clone/models/repositories/theme_change_repository.dart';
import 'package:insta_clone/view_models/login_view_model.dart';
import 'package:insta_clone/view_models/theme_change_view_model.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';
import 'view/home_screen.dart';
import 'view/login/screens/login_screen.dart';
import 'package:timeago/timeago.dart' as timeAgo; //トップレベル関数を指定するため

void main() async {
  //runAppの中にある必ず一番最初に動作するメソッドを追記
  WidgetsFlutterBinding.ensureInitialized();

  //テーマの設定読み出し
  final themeChangeRepository = ThemeChangeRepository();
  await themeChangeRepository.getIsDarkOn();

  //時刻表示のロケール(言語)設定
  timeAgo.setLocaleMessages("ja", timeAgo.JaMessages());

  runApp(MultiProvider(
    providers: globalProviders,
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
//    final loginViewModel = context.read();
    final themeChangeViewModel = Provider.of<ThemeChangeViewModel>(context);

    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      title: "DaitaInstagram",
      debugShowCheckedModeBanner: false,
      theme: themeChangeViewModel.selectedTheme,
      home: FutureBuilder(
        future: loginViewModel.isSingIn(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData && snapshot.data) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
