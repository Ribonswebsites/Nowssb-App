import '../../../kit/kit.dart';

/// `newui_gifts` through the shared kit ([NewUi]): debug override →
/// remote `config/app.flags.newui_gifts` → admins on → everyone else off.
bool newUiGiftsEnabled({bool? override}) => override ?? NewUi.isOn('gifts');
