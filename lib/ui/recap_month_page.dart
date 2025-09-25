import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/nota.dart';
import '../services/hive_service.dart';

class RecapMonthPage extends StatefulWidget {
  final bool showFab;
  const RecapMonthPage({super.key, this.showFab = false});

  @override
  State<RecapMonthPage> createState() => _RecapMonthPageState();
}

class _RecapMonthPageState extends State<RecapMonthPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final mf = DateFormat('MMMM yyyy', 'id_ID');
    final df = DateFormat('dd MMM', 'id_ID');
    final cf = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final notas = HiveService.instance.notasByMonth(_month);
    final total = notas.fold<double>(0, (p, n) => p + n.total);

    // Group by day
    final Map<String, List<Nota>> byDay = {};
    for (final n in notas) {
      final key = DateFormat('yyyy-MM-dd').format(n.date);
      byDay.putIfAbsent(key, () => []).add(n);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Bulanan'),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _month,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                helpText: 'Pilih tanggal apapun dalam bulan',
              );
              if (picked != null)
                setState(() => _month = DateTime(picked.year, picked.month, 1));
            },
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pilih Bulan',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.05),
              Colors.blueGrey.withOpacity(0.03),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month, size: 18),
                              Text(
                                mf.format(_month),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Transaksi: ${notas.length}'),
                        ],
                      ),
                    ),
                    Text(
                      cf.format(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...byDay.entries.map((e) {
              final date = DateTime.parse('${e.key}T00:00:00.000');
              final list = e.value;
              final sum = list.fold<double>(0, (p, n) => p + n.total);
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text('${df.format(date)} • ${list.length} transaksi'),
                  trailing: Text(
                    cf.format(sum),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  childrenPadding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: 12,
                  ),
                  children:
                      list
                          .map(
                            (n) => Dismissible(
                              key: ValueKey('m-${n.id}'),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              secondaryBackground: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            title: const Text('Hapus Nota?'),
                                            content: Text(
                                              'Hapus nota ${n.invoiceNo} milik ${n.customerName}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      false,
                                                    ),
                                                child: const Text('Batal'),
                                              ),
                                              FilledButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      true,
                                                    ),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) async {
                                await HiveService.instance.deleteNota(n.id);
                                if (!context.mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Nota dihapus')),
                                );
                              },
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  '${n.customerName} • ${n.deviceType}',
                                ),
                                subtitle: Text('Inv ${n.invoiceNo}'),
                                trailing: Text(cf.format(n.total)),
                              ),
                            ),
                          )
                          .toList(),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
