import 'package:hive/hive.dart';
import '../models/nota.dart';

class HiveService {
  HiveService._();
  static final instance = HiveService._();

  static const String notaBoxName = 'notaBox';

  late Box<Nota> _notaBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(NotaAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(NotaItemAdapter());
    _notaBox = await Hive.openBox<Nota>(notaBoxName);
  }

  Future<void> addNota(Nota nota) async {
    await _notaBox.put(nota.id, nota);
  }

  Future<void> deleteNota(String id) async {
    await _notaBox.delete(id);
  }

  List<Nota> notasByDate(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _notaBox.values
        .where((n) => n.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && n.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Nota> notasByMonth(DateTime anyDayInMonth) {
    final start = DateTime(anyDayInMonth.year, anyDayInMonth.month, 1);
    final end = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 1);
    return _notaBox.values
        .where((n) => n.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && n.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Nota> allNotas() => _notaBox.values.toList();

  String nextInvoiceNoForDate(DateTime date) => ensureUniqueInvoiceNo(date);

  String ensureUniqueInvoiceNo(
    DateTime date, {
    String? preferred,
    String? excludeNotaId,
  }) {
    final prefix = _invoicePrefix(date);
    final used = notasByDate(date)
        .where((nota) => nota.id != excludeNotaId)
        .map((nota) => nota.invoiceNo)
        .toSet();

    if (preferred != null && preferred.startsWith(prefix) && !used.contains(preferred)) {
      return preferred;
    }

    var counter = 1;
    while (true) {
      final candidate = '$prefix${counter.toString().padLeft(2, '0')}';
      if (!used.contains(candidate)) return candidate;
      counter++;
    }
  }

  String _invoicePrefix(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
