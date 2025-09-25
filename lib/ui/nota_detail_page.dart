import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../services/bluetooth_service.dart';
import '../services/print_service.dart';
import 'widgets/nota_a6_widget.dart';

class NotaDetailPage extends StatefulWidget {
  static const routeName = '/detail';
  final Nota nota;
  const NotaDetailPage({super.key, required this.nota});

  @override
  State<NotaDetailPage> createState() => _NotaDetailPageState();
}

class _NotaDetailPageState extends State<NotaDetailPage> {
  final _key = GlobalKey();
  final bt = BluetoothService.instance;
  bool _printing = false;
  bool _adaptivePreview = true;

  Future<void> _choosePrinter() async {
    await bt.refreshDevices();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.builder(
            itemCount: bt.devices.length,
            itemBuilder: (c, i) {
              final d = bt.devices[i];
              return ListTile(
                title: Text(d.name ?? 'Unknown'),
                subtitle: Text(d.address ?? ''),
                onTap: () => Navigator.pop(ctx, i),
              );
            },
          ),
        );
      },
    );
    if (chosen != null) {
      final ok = await bt.connect(bt.devices[chosen]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Terhubung ke ${bt.devices[chosen].name}' : 'Gagal konek',
          ),
        ),
      );
    }
  }

  Future<void> _print() async {
    setState(() {
      _printing = true;
      _adaptivePreview = false;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final Uint8List png = await PrintService.captureToPng(
        _key,
        pixelRatio: 3,
        rotateClockwise: true,
      );
      await bt.printImageBytes(png);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terkirim ke printer')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal cetak: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _printing = false;
          _adaptivePreview = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Nota A6'),
        actions: [
          IconButton(
            onPressed: _choosePrinter,
            icon: const Icon(Icons.bluetooth_searching),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: RepaintBoundary(
            key: _key,
            child: NotaA6Widget(
              nota: widget.nota,
              adaptive: _adaptivePreview,
              logoImage: const AssetImage('assets/images/logo.png'),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _printing ? null : _print,
            icon:
                _printing
                    ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.print),
            label: const Text('Cetak Bluetooth'),
          ),
        ),
      ),
    );
  }
}
