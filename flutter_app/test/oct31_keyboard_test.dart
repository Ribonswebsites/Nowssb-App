import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/login_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'fake_video_platform.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VideoPlayerPlatform.instance = FakeVideoPlatform();
  });

  testWidgets('Login: email goes Next, password keyboard action signs in', (t) async {
    var submits = 0;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: LoginStage(
        id: TextEditingController(),
        secret: TextEditingController(),
        busy: false,
        obscure: true,
        remember: false,
        createAccount: false,
        codeSent: false,
        onSubmit: () => submits++,
        onGoogle: () {},
        onApple: () {},
        onForgot: () {},
        onToggleCreate: () {},
        onToggleObscure: () {},
        onToggleRemember: () {},
      )),
    ));
    await t.pump(const Duration(milliseconds: 300));
    final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.length, greaterThanOrEqualTo(2));
    expect(fields[0].textInputAction, TextInputAction.next);
    expect(fields[1].textInputAction, TextInputAction.go);
    await t.showKeyboard(find.byType(TextField).at(1));
    await t.testTextInput.receiveAction(TextInputAction.go);
    await t.pump();
    expect(submits, 1);
  });
}
