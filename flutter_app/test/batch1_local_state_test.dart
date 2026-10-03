import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _ymd(DateTime n) => '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily task "done" keys older than a week are pruned', () async {
    final now = DateTime.now();
    final old = _ymd(now.subtract(const Duration(days: 30)));
    final recent = _ymd(now.subtract(const Duration(days: 2)));
    SharedPreferences.setMockInitialValues({
      'nwsb_task_done_local_$old': <String>['breath'],
      'nwsb_task_done_abc123_$old': <String>['breath'],
      'nwsb_task_done_local_$recent': <String>['breath'],
      'unrelated_key': 'x',
    });
    await DailyTasks.publish();
    final p = await SharedPreferences.getInstance();
    expect(p.containsKey('nwsb_task_done_local_$old'), isFalse);
    expect(p.containsKey('nwsb_task_done_abc123_$old'), isFalse);
    expect(p.containsKey('nwsb_task_done_local_$recent'), isTrue);
    expect(p.containsKey('unrelated_key'), isTrue);
  });

  test('signed-out practice history loads from the device key', () async {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'nwsb_native_sessions': '{"${day}_Om":{"date":"$day","word":"Om"}}',
    });
    await PracticeProgress.instance.start();
    expect(PracticeProgress.instance.thisWeekDays.where((d) => d.isToday).single.done, isTrue);
  });
}
