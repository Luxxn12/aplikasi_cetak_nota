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
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    bt.addListener(_onBluetoothChange);
  }

  void _onBluetoothChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    bt.removeListener(_onBluetoothChange);
    super.dispose();
  }

  Future<void> _choosePrinter() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
    });
    BuildContext? dialogContext;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const _ScanningDialog();
      },
    );
    try {
      await bt.refreshDevices();
    } finally {
      if (mounted) {
        if (dialogContext != null &&
            Navigator.of(dialogContext!).canPop()) {
          Navigator.of(dialogContext!).pop();
        }
        setState(() {
          _scanning = false;
        });
      }
    }
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
                leading: const Icon(Icons.print, color: Colors.blueGrey),
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
      bt.setAutoRotate(true); // biarkan service yang putar otomatis
      bt.setPrintSize(widthMm: 90, heightMm: 200); // roll 90mm, feed 150mm
      bt.setDotsPerMillimeter(8.0); // 203 dpi -> 8 dots/mm
      bt.setOuterMargin(0.5); // 0–0.5mm agar aman dari hardware margin
      bt.setTrailingFeedReduction(50); // kurangi area putih trailing 50mm
      bt.setPrintDensity(12); // tingkatkan kepadatan agar teks lebih pekat
      bt.setPrintSpeed(2); // sedikit perlambat supaya panas lebih merata
      bt.setBinarizationThreshold(210); // dorong konversi hitam supaya font solid

      final Uint8List png = await PrintService.captureToPng(
        _key,
        pixelRatio: 3,
        rotateClockwise: false, // JANGAN putar di sini
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    bt.connectedDevice != null
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color:
                        bt.connectedDevice != null
                            ? Colors.green
                            : Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 120,
                    child: Text(
                      bt.connectedDevice?.name ?? 'Belum terhubung',
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _scanning ? null : _choosePrinter,
            icon:
                _scanning
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.bluetooth_searching),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: RepaintBoundary(
            key: _key,
            child: Builder(
              builder: (context) {
                final content = NotaA6Widget(
                  nota: widget.nota,
                  adaptive: _adaptivePreview,
                  logoImage: const AssetImage('assets/images/logo.png'),
                  // Samakan ukuran teks preview dan cetak
                  textScale: 1.0,
                );
                // Putar 90° hanya untuk pratinjau (saat _adaptivePreview = true)
                return _adaptivePreview
                    ? RotatedBox(quarterTurns: 1, child: content)
                    : content;
              },
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

class _ScanningDialog extends StatelessWidget {
  const _ScanningDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Mencari perangkat...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
