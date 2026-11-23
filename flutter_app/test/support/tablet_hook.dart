// The app's MaterialApp.builder wrapper, for tests that render the whole
// app. (A baseline checkout without the tablet frame swaps this file for
// one that returns the child, so the same shots can be compared.)
import 'package:flutter/material.dart';
import 'package:nowssb/shell/tablet_frame.dart';

Widget wrapAppFrame(GlobalKey<NavigatorState> nav, Widget child) =>
    TabletFrame(navigatorKey: nav, child: child);

List<NavigatorObserver> appFrameObservers() => [TabletShellGate.observer];
