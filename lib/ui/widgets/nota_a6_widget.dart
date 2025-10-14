import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../../models/nota.dart';

class NotaA6Widget extends StatelessWidget {
  final Nota nota;
  final double mm;
  final bool adaptive;
  final ImageProvider<Object>? logoImage;
  final double textScale;
  const NotaA6Widget({
    super.key,
    required this.nota,
    this.mm = 8,
    this.adaptive = true,
    this.logoImage,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Nota portrait ±90mm x 140mm; akan diputar 90° saat cetak supaya menjadi 140mm x 90mm
    final width = 140 * mm;
    final height = 90 * mm;
    final df = DateFormat('dd MMM yyyy');
    final cf = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    Widget buildContent() {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black87, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(df: df, nota: nota, logoImage: logoImage),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.black87, width: 1),
                columnWidths: const {
                  0: FixedColumnWidth(48),
                  1: FlexColumnWidth(4),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2),
                },
                children: [
                  const TableRow(
                    children: [
                      _Cell('NO', bold: true),
                      _Cell('PENGGANTI KOMPONEN', bold: true),
                      _Cell('HARGA BARANG', bold: true),
                      _Cell('SERVICE', bold: true),
                      _Cell('TOTAL PRICE', bold: true),
                    ],
                  ),
                  ...nota.items.asMap().entries.map((e) {
                    final i = e.key + 1;
                    final it = e.value;
                    return TableRow(
                      children: [
                        _Cell(i.toString()),
                        _Cell(it.description),
                        _Cell(cf.format(it.barang), align: TextAlign.right),
                        _Cell(cf.format(it.service), align: TextAlign.right),
                        _Cell(cf.format(it.totalPrice), align: TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              const Spacer(),
              _Footer(cf: cf, nota: nota),
            ],
          ),
        ),
      );
    }

    final media = MediaQuery.of(context);
    final original = MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: buildContent(),
      ),
    );

    if (!adaptive) return original;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : media.size.width;
        final availableHeight =
            constraints.hasBoundedHeight
                ? constraints.maxHeight
                : media.size.height;

        double scale = math.min(
          availableWidth / width,
          availableHeight.isFinite ? availableHeight / height : 1.0,
        );
        if (scale > 1) scale = 1;
        if (scale < 1) {
          final scaledWidth = width * scale;
          final scaledHeight = height * scale;
          return SizedBox(
            width: scaledWidth,
            height: scaledHeight,
            child: FittedBox(alignment: Alignment.topLeft, child: original),
          );
        }
        return original;
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.df, required this.nota, this.logoImage});

  final DateFormat df;
  final Nota nota;
  final ImageProvider<Object>? logoImage;

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF0B4DAA);
    final infoStyle = Theme.of(context).textTheme.bodySmall;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoBadge(image: logoImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'SERVICE MICROWAVE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text('Jl. Gn. Atena I No. 11 A, Padangsambian Klod,'),
                    Text('Kec. Denpasar Bar., Kota Denpasar, Bali - 80361'),
                    SizedBox(height: 4),
                    Text('WA: 0857 3765 5537'),
                    Text('BCA : 6485 2413 31 a.n. Cahyono'),
                    Text('BRI : 7629 0100 8554 537 a.n. Cahyono'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama : ${nota.customerName}', style: infoStyle),
            Text('Tipe : ${nota.deviceType}', style: infoStyle),
            Text('Tgl  : ${df.format(nota.date)}', style: infoStyle),
            Text(
              'INVOICE : ${nota.invoiceNo}',
              style: infoStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.cf, required this.nota});

  final NumberFormat cf;
  final Nota nota;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Garansi Service 1 Bulan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Signature',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 120,
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1),
              ),
              child: Text(
                'Grand Total  ${cf.format(nota.total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({this.image});

  final ImageProvider<Object>? image;

  static Future<Uint8List?>? _bytesFuture;
  static const _candidateAssets = [
    'assets/images/logo.jpg',
    'assets/images/logo.jpeg',
    'assets/images/logo.png',
    'assets/images/logo.webp',
  ];

  static Future<Uint8List?> _loadLogoBytes() {
    _bytesFuture ??= () async {
      for (final path in _candidateAssets) {
        try {
          final data = await rootBundle.load(path);
          return data.buffer.asUint8List();
        } catch (_) {
          continue;
        }
      }
      return null;
    }();
    return _bytesFuture!;
  }

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return _DecoratedLogo(image: image);
    }
    return FutureBuilder<Uint8List?>(
      future: _loadLogoBytes(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done && data != null) {
          return _DecoratedLogo.memory(data);
        }
        return const _FallbackBadge();
      },
    );
  }
}

class _DecoratedLogo extends StatelessWidget {
  const _DecoratedLogo({this.image, this.bytes})
    : assert(image != null || bytes != null);

  final ImageProvider<Object>? image;
  final Uint8List? bytes;

  factory _DecoratedLogo.memory(Uint8List bytes) =>
      _DecoratedLogo(bytes: bytes);

  @override
  Widget build(BuildContext context) {
    Widget buildFallback(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) {
      return const _FallbackBadge();
    }

    final widget =
        bytes != null
            ? Image.memory(
              bytes!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: buildFallback,
            )
            : Image(
              image: image!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: buildFallback,
            );
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: widget);
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final TextAlign align;
  const _Cell(this.text, {this.bold = false, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
      ),
    );
  }
}

class _FallbackBadge extends StatelessWidget {
  const _FallbackBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF5DA3F0), Color(0xFF0B4DAA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'MICROWAVE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'DENPASAR',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
