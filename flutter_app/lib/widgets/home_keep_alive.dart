/// Keeps a Home section mounted after it scrolls away, so videos and
/// sections do not reload when you scroll back up.
library;

import 'package:flutter/widgets.dart';

class HomeKeepAlive extends StatefulWidget {
  const HomeKeepAlive({super.key, required this.child});
  final Widget child;
  @override
  State<HomeKeepAlive> createState() => _HomeKeepAliveState();
}

class _HomeKeepAliveState extends State<HomeKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
