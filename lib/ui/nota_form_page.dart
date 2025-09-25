import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/nota.dart';
import '../services/hive_service.dart';

class NotaFormPage extends StatefulWidget {
  const NotaFormPage({super.key});

  @override
  State<NotaFormPage> createState() => _NotaFormPageState();
}

class _NotaFormPageState extends State<NotaFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _type = TextEditingController();
  final _invoice = TextEditingController(text: '0001');
  DateTime _date = DateTime.now();

  final List<_ItemRow> _rows = [
    _ItemRow(),
  ];
  final _currencyFormatter = CurrencyInputFormatter();

  double _parseCurrency(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return double.parse(digits);
  }

  String? _requiredMoneyValidator(String? value) {
    if (value == null || value.isEmpty) return 'Wajib';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Wajib';
    return null;
  }

  void _addRow() => setState(() => _rows.add(_ItemRow()));
  void _removeRow(int i) => setState(() => _rows.removeAt(i));

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text('Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void initState() {
    super.initState();
    _invoice.text = HiveService.instance.nextInvoiceNoForDate(_date);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final items = _rows
        .map((e) => NotaItem(
              description: e.desc.text,
              barang: _parseCurrency(e.harga.text),
              service: _parseCurrency(e.service.text),
            ))
        .toList();

    final uniqueInvoice = HiveService.instance.ensureUniqueInvoiceNo(
      _date,
      preferred: _invoice.text,
    );
    _invoice.text = uniqueInvoice;

    final nota = Nota(
      id: const Uuid().v4(),
      customerName: _name.text,
      deviceType: _type.text,
      date: _date,
      invoiceNo: uniqueInvoice,
      items: items,
    );
    await HiveService.instance.addNota(nota);
    if (!mounted) return;
    setState(() {
      _invoice.text = HiveService.instance.nextInvoiceNoForDate(_date);
    });
    Navigator.pushNamed(context, '/rekap');
  }

  void _toPreview() {
    if (!_form.currentState!.validate()) return;
    final items = _rows
        .map((e) => NotaItem(
              description: e.desc.text,
              barang: _parseCurrency(e.harga.text),
              service: _parseCurrency(e.service.text),
            ))
        .toList();
    final uniqueInvoice = HiveService.instance.ensureUniqueInvoiceNo(
      _date,
      preferred: _invoice.text,
    );
    if (_invoice.text != uniqueInvoice) {
      setState(() {
        _invoice.text = uniqueInvoice;
      });
    }
    final nota = Nota(
      id: const Uuid().v4(),
      customerName: _name.text,
      deviceType: _type.text,
      date: _date,
      invoiceNo: uniqueInvoice,
      items: items,
    );
    Navigator.pushNamed(context, '/detail', arguments: nota);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final cf = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final radius = BorderRadius.circular(10);

    InputDecoration decoration({
      String? label,
      String? hint,
      IconData? prefixIcon,
      Widget? suffix,
    }) {
      final theme = Theme.of(context);
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      );
    }

    double subtotal = 0;
    for (final r in _rows) {
      final b = _parseCurrency(r.harga.text);
      final s = _parseCurrency(r.service.text);
      subtotal += b + s;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nota'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.withOpacity(0.05), Colors.blueGrey.withOpacity(0.03)],
          ),
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 520;
                        final gap = isWide
                            ? const SizedBox(width: 12)
                            : const SizedBox(height: 12);

                        Widget buildNameType() {
                          final nameField = TextFormField(
                            controller: _name,
                            decoration: decoration(
                              label: 'Nama Pelanggan',
                              prefixIcon: Icons.person_outline,
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                          );

                          final typeField = TextFormField(
                            controller: _type,
                            decoration: decoration(
                              label: 'Tipe/Barang',
                              prefixIcon: Icons.devices_other_outlined,
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                          );

                          if (isWide) {
                            return Row(children: [
                              Expanded(child: nameField),
                              const SizedBox(width: 12),
                              Expanded(child: typeField),
                            ]);
                          }

                          return Column(children: [
                            nameField,
                            gap,
                            typeField,
                          ]);
                        }

                        Widget buildDateInvoice() {
                          final dateField = InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _date = picked;
                                  _invoice.text = HiveService.instance.nextInvoiceNoForDate(_date);
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: decoration(
                                label: 'Tanggal',
                                prefixIcon: Icons.event_outlined,
                              ),
                              child: Text(df.format(_date)),
                            ),
                          );

                          final invoiceField = TextFormField(
                            controller: _invoice,
                            readOnly: true,
                            decoration: decoration(
                              label: 'Invoice No',
                              prefixIcon: Icons.tag_outlined,
                              suffix: IconButton(
                                tooltip: 'Generate ulang',
                                icon: const Icon(Icons.refresh),
                                onPressed: () => setState(() {
                                  _invoice.text = HiveService.instance.nextInvoiceNoForDate(_date);
                                }),
                              ),
                            ),
                          );

                          if (isWide) {
                            return Row(children: [
                              Expanded(child: dateField),
                              const SizedBox(width: 12),
                              Expanded(child: invoiceField),
                            ]);
                          }

                          return Column(children: [
                            dateField,
                            gap,
                            invoiceField,
                          ]);
                        }

                        return Column(
                          children: [
                            buildNameType(),
                            const SizedBox(height: 12),
                            buildDateInvoice(),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 560;
                        const descLabel = 'Deskripsi komponen / jasa';
                        const barangLabel = 'Harga barang';
                        const serviceLabel = 'Biaya service';
                        final title = isWide
                            ? const Row(
                                children: [
                                  Expanded(flex: 5, child: Text('Pengganti Komponen', style: TextStyle(fontWeight: FontWeight.w600))),
                                  Expanded(flex: 3, child: Text('Harga Barang', style: TextStyle(fontWeight: FontWeight.w600))),
                                  Expanded(flex: 3, child: Text('Service', style: TextStyle(fontWeight: FontWeight.w600))),
                                  SizedBox(width: 40),
                                ],
                              )
                            : const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengganti Komponen', style: TextStyle(fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('Harga Barang', style: TextStyle(fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('Service', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              );

                        Widget buildRow(_ItemRow row, int i) {
                          if (isWide) {
                            return Row(children: [
                              Expanded(
                                flex: 5,
                                child: TextFormField(
                                  controller: row.desc,
                                  decoration: decoration(label: descLabel),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.harga,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [_currencyFormatter],
                                  decoration: decoration(label: barangLabel),
                                  validator: _requiredMoneyValidator,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.service,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [_currencyFormatter],
                                  decoration: decoration(label: serviceLabel),
                                  validator: _requiredMoneyValidator,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              Tooltip(
                                message: 'Hapus baris',
                                child: IconButton(
                                  onPressed: _rows.length == 1 ? null : () => _removeRow(i),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            ]);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: row.desc,
                                decoration: decoration(label: descLabel),
                                validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: row.harga,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_currencyFormatter],
                                decoration: decoration(label: barangLabel),
                                validator: _requiredMoneyValidator,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: row.service,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [_currencyFormatter],
                                      decoration: decoration(label: serviceLabel),
                                      validator: _requiredMoneyValidator,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Hapus baris',
                                    child: IconButton(
                                      onPressed: _rows.length == 1 ? null : () => _removeRow(i),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: isWide ? 6 : 0),
                              child: title,
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            ..._rows.asMap().entries.map((e) {
                              final i = e.key;
                              final row = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: buildRow(row, i),
                              );
                            }).toList(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _addRow,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Tambah Item'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w600))),
                        Text(cf.format(subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toPreview,
                  icon: const Icon(Icons.print),
                  label: const Text('Pratinjau / Cetak'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow {
  final desc = TextEditingController();
  final harga = TextEditingController();
  final service = TextEditingController();
}

class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter()
      : _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final number = int.parse(digits);
    final formatted = _formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
