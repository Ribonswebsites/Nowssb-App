import '../../../data/app_control.dart';

/// Feature flag for the rebuilt Progress page: `newui_progress`.
/// ON for everyone by default; the console may set the key to false as a
/// kill switch (config flags map, read by [AppControl]).
bool newUiProgressEnabled({bool? override}) {
  if (override != null) return override;
  return AppControl.instance.flags['newui_progress'] != false;
}
