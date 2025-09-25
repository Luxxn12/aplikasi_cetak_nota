import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/nota.dart';
import '../services/hive_service.dart';
import 'nota_detail_page.dart';

class RecapPage extends StatefulWidget {
  final bool showFab;
  const RecapPage({super.key, this.showFab = true});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  DateTime _filterDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM yyyy');
    final cf = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final notas = HiveService.instance.notasByDate(_filterDate);
    final total = notas.fold<double>(0, (p, n) => p + n.total);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Harian'),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _filterDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _filterDate = picked);
            },
            icon: const Icon(Icons.today),
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.withOpacity(0.04), Colors.teal.withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            const Icon(Icons.today, size: 18),
                            Text(df.format(_filterDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Text('Transaksi: ${notas.length}')
                        ],
                      ),
                    ),
                    Text(cf.format(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...notas.map((n) => Dismissible(
                  key: ValueKey(n.id),
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Nota?'),
                            content: Text('Hapus nota ${n.invoiceNo} milik ${n.customerName}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    await HiveService.instance.deleteNota(n.id);
                    if (!context.mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota dihapus')));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text('${n.customerName} • ${n.deviceType}'),
                      subtitle: Text('${n.invoiceNo} • ${df.format(n.date)}'),
                      trailing: Text(cf.format(n.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotaDetailPage(nota: n)),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: widget.showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushReplacementNamed(context, '/input'),
              icon: const Icon(Icons.add),
              label: const Text('Nota Baru'),
            )
          : null,
    );
  }
}
