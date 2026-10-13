/// Honest milestones: each one is earned from real practice, with no
/// timers, countdowns or loss framing. Locked ones show the plain goal.
library;

import 'profile_data.dart';

class Milestone {
  const Milestone(this.id, this.title, this.goal, this.earned);
  final String id;
  final String title;
  final String goal;
  final bool earned;
}

List<Milestone> milestonesFor(ProfileData d) => [
      Milestone('first', 'First breath', 'Finish 1 session', d.sessions >= 1),
      Milestone('streak3', 'Three calm days', 'Practice 3 days in a row', d.streak >= 3),
      Milestone('min60', 'One quiet hour', 'Practice 60 minutes in total', d.minutes >= 60),
      Milestone('sess25', 'Steady path', 'Finish 25 sessions', d.sessions >= 25),
      Milestone('streak7', 'Full week', 'Practice 7 days in a row', d.streak >= 7),
    ];
