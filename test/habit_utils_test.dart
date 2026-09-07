import 'package:flutter_test/flutter_test.dart';
import 'package:abidlife/data/models.dart';
import 'package:abidlife/utils/habit_utils.dart';
import 'package:abidlife/utils/date_utils.dart' as abid;

void main() {
  group('HabitUtils.scheduledOn', () {
    final daily = Habit(
      id: 'h1',
      name: 'Drink Water',
      icon: 'Droplet',
      color: 'blue',
      frequency: const Frequency(type: FrequencyType.daily),
      reminder: false,
      archived: false,
      createdAt: DateTime(2024, 1, 1),
    );
    final weekly = Habit(
      id: 'h2',
      name: 'Workout',
      icon: 'Dumbbell',
      color: 'green',
      // Mon, Wed, Fri (web convention: 1=Mon, 3=Wed, 5=Fri)
      frequency: const Frequency(type: FrequencyType.days, days: [1, 3, 5]),
      reminder: false,
      archived: false,
      createdAt: DateTime(2024, 1, 1),
    );

    test('daily habit is scheduled every day', () {
      for (var i = 0; i < 7; i++) {
        final d = DateTime(2024, 8, 5 + i);
        expect(HabitUtils.scheduledOn(daily, d), isTrue,
            reason: 'day ${d.weekday} should be scheduled');
      }
    });

    test('weekly habit is scheduled only on Mon/Wed/Fri', () {
      // 2024-08-05 is a Monday.
      expect(HabitUtils.scheduledOn(weekly, DateTime(2024, 8, 5)), isTrue); // Mon
      expect(HabitUtils.scheduledOn(weekly, DateTime(2024, 8, 6)), isFalse); // Tue
      expect(HabitUtils.scheduledOn(weekly, DateTime(2024, 8, 7)), isTrue); // Wed
      expect(HabitUtils.scheduledOn(weekly, DateTime(2024, 8, 8)), isFalse); // Thu
      expect(HabitUtils.scheduledOn(weekly, DateTime(2024, 8, 9)), isTrue); // Fri
    });
  });

  group('HabitUtils.getStreaks', () {
    final habit = Habit(
      id: 'h1',
      name: 'Meditation',
      icon: 'Brain',
      color: 'violet',
      frequency: const Frequency(type: FrequencyType.daily),
      reminder: false,
      archived: false,
      createdAt: DateTime(2024, 7, 1),
    );

    test('empty logs → 0 / 0', () {
      final s = HabitUtils.getStreaks(habit, <String>{}, now: DateTime(2024, 8, 5));
      expect(s.current, 0);
      expect(s.best, 0);
    });

    test('5 consecutive days ending yesterday → 5 current / 5 best', () {
      final now = DateTime(2024, 8, 5); // Monday
      final dates = <String>{
        abid.AbidDates.dateStr(DateTime(2024, 7, 31)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 1)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 2)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 3)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 4)),
      };
      final s = HabitUtils.getStreaks(habit, dates, now: now);
      expect(s.current, 5);
      expect(s.best, 5);
    });

    test('streak broken by missing yesterday → 0 current', () {
      final now = DateTime(2024, 8, 5);
      final dates = <String>{
        abid.AbidDates.dateStr(DateTime(2024, 8, 3)),
      };
      final s = HabitUtils.getStreaks(habit, dates, now: now);
      expect(s.current, 0);
      expect(s.best, 1);
    });

    test('best streak counts a longer past streak', () {
      final now = DateTime(2024, 8, 10);
      final dates = <String>{
        abid.AbidDates.dateStr(DateTime(2024, 7, 20)),
        abid.AbidDates.dateStr(DateTime(2024, 7, 21)),
        abid.AbidDates.dateStr(DateTime(2024, 7, 22)),
        abid.AbidDates.dateStr(DateTime(2024, 7, 23)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 8)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 9)),
      };
      final s = HabitUtils.getStreaks(habit, dates, now: now);
      expect(s.current, 2);
      expect(s.best, 4);
    });
  });

  group('HabitUtils.completionRate', () {
    final habit = Habit(
      id: 'h1',
      name: 'Read',
      icon: 'BookOpen',
      color: 'amber',
      frequency: const Frequency(type: FrequencyType.daily),
      reminder: false,
      archived: false,
      createdAt: DateTime(2024, 7, 1),
    );

    test('50% completion over last 4 days', () {
      final now = DateTime(2024, 8, 5);
      final dates = <String>{
        abid.AbidDates.dateStr(DateTime(2024, 8, 5)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 3)),
      };
      // Over last 4 days (Aug 2, 3, 4, 5) we have 2 done → 50%.
      final rate = HabitUtils.completionRate(habit, dates, days: 4, now: now);
      expect(rate, 50);
    });

    test('100% completion', () {
      final now = DateTime(2024, 8, 5);
      final dates = <String>{
        abid.AbidDates.dateStr(DateTime(2024, 8, 2)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 3)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 4)),
        abid.AbidDates.dateStr(DateTime(2024, 8, 5)),
      };
      final rate = HabitUtils.completionRate(habit, dates, days: 4, now: now);
      expect(rate, 100);
    });
  });

  group('HabitUtils.nextOccurrenceDate', () {
    test('daily → tomorrow', () {
      final next = HabitUtils.nextOccurrenceDate(
        dueDate: '2024-08-05',
        recurrence: 'daily',
        repeatDays: const [],
      );
      expect(next, '2024-08-06');
    });

    test('monthly → next month same day', () {
      final next = HabitUtils.nextOccurrenceDate(
        dueDate: '2024-08-05',
        recurrence: 'monthly',
        repeatDays: const [],
      );
      expect(next, '2024-09-05');
    });

    test('weekly → next weekday in repeatDays', () {
      // 2024-08-05 is a Monday (web weekday=1). Repeat on Mon/Wed/Fri (1,3,5).
      // Next occurrence should be Wed (2024-08-07).
      final next = HabitUtils.nextOccurrenceDate(
        dueDate: '2024-08-05',
        recurrence: 'weekly',
        repeatDays: const [1, 3, 5],
      );
      expect(next, '2024-08-07');
    });
  });
}
