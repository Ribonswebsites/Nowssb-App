/// Rebuilt Earn, Rewards, Gifts and Coupons. Old pages are not used.
library;

import 'package:flutter/material.dart';

import '../../widgets/hub_rails.dart';

class ProgramHub extends StatefulWidget {
  const ProgramHub({super.key, required this.title, required this.subs, this.focus});

  final String title;
  final List<String> subs;
  final String? focus;

  @override
  State<ProgramHub> createState() => _ProgramHubState();
}

class _ProgramHubState extends State<ProgramHub> {
  late String _sub = widget.focus ?? widget.subs.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                Expanded(child: Text(widget.focus ?? widget.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
              ],
            ),
            if (widget.focus == null)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in widget.subs)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: _sub == s,
                          onSelected: (_) {
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => ProgramHub(title: widget.title, subs: widget.subs, focus: s),
                            ));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            HubRails(
              a: railSet(['${widget.focus ?? widget.title}', 'Today', 'For you', 'Limited', 'Saved'], '4 min'),
              b: railSet(['Open', 'In progress', 'Done', 'Saved', 'New'], _sub),
              c: railSet(['7 day', 'Streak', 'First time', 'Weekly', 'Invite'], 'a short step'),
            ),
          ],
        ),
      ),
    );
  }
}
