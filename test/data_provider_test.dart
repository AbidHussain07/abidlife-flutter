import 'package:flutter_test/flutter_test.dart';
import 'package:abidlife/data/models.dart';

void main() {
  group('Frequency encoding (round-trip)', () {
    test('daily round-trips through encode/decode', () {
      const f = Frequency(type: FrequencyType.daily);
      final s = f.encode();
      expect(s, '{"type":"daily"}');
      expect(Frequency.decode(s), f);
    });

    test('days round-trips through encode/decode', () {
      const f = Frequency(type: FrequencyType.days, days: [0, 1, 3, 5]);
      final s = f.encode();
      expect(s, '{"type":"days","days":0,1,3,5}');
      final decoded = Frequency.decode(s);
      expect(decoded.type, FrequencyType.days);
      expect(decoded.days, [0, 1, 3, 5]);
    });

    test('null input decodes to daily', () {
      expect(Frequency.decode(null).type, FrequencyType.daily);
      expect(Frequency.decode('').type, FrequencyType.daily);
    });
  });

  group('Note serialization', () {
    final note = Note(
      id: 'n1',
      title: 'Hello',
      content: 'World',
      color: 'blue',
      tags: const ['work', 'idea'],
      pinned: true,
      archived: false,
      locked: false,
      checklist: false,
      createdAt: DateTime(2024, 8, 5, 10, 0),
      updatedAt: DateTime(2024, 8, 5, 11, 0),
    );

    test('toRow / fromRow round-trip', () {
      final row = note.toRow();
      final restored = Note.fromRow(row);
      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.content, note.content);
      expect(restored.color, note.color);
      expect(restored.tags, note.tags);
      expect(restored.pinned, note.pinned);
      expect(restored.archived, note.archived);
      expect(restored.locked, note.locked);
      expect(restored.checklist, note.checklist);
    });

    test('tags are comma-encoded', () {
      expect(note.toRow()['tags'], 'work,idea');
      expect(Note.fromRow({'tags': 'work,idea', 'id': 'x', 'createdAt': '2024-08-05T10:00:00.000', 'updatedAt': '2024-08-05T10:00:00.000'}).tags,
          ['work', 'idea']);
    });
  });

  group('Task serialization', () {
    final task = Task(
      id: 't1',
      title: 'Buy groceries',
      notes: 'milk, eggs',
      done: false,
      priority: 'high',
      category: 'Personal',
      dueDate: '2024-08-05',
      dueTime: '14:30',
      reminder: true,
      recurrence: 'weekly',
      repeatDays: const [1, 3, 5],
      completedAt: null,
      createdAt: DateTime(2024, 8, 1),
    );

    test('toRow / fromRow round-trip', () {
      final restored = Task.fromRow(task.toRow());
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.priority, task.priority);
      expect(restored.dueTime, task.dueTime);
      expect(restored.reminder, task.reminder);
      expect(restored.recurrence, task.recurrence);
      expect(restored.repeatDays, task.repeatDays);
    });
  });

  group('Txn serialization', () {
    final txn = Txn(
      id: 'x1',
      accountId: 'a1',
      type: TxnType.income,
      amount: 12345,
      note: 'Salary',
      category: 'Salary',
      occurredAt: DateTime(2024, 8, 5, 9, 30),
      createdAt: DateTime(2024, 8, 5, 9, 30),
    );

    test('toRow / fromRow round-trip', () {
      final restored = Txn.fromRow(txn.toRow());
      expect(restored.id, txn.id);
      expect(restored.type, txn.type);
      expect(restored.amount, txn.amount);
      expect(restored.category, txn.category);
    });
  });
}
