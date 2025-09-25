import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/nota.dart';
import 'services/hive_service.dart';
import 'ui/login_page.dart';
import 'ui/nota_form_page.dart';
import 'ui/recap_page.dart';
import 'ui/nota_detail_page.dart';
import 'ui/home_page.dart';
import 'ui/recap_month_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
  } catch (_) {
    // Fallback for test environments where plugins are not registered
    final tmp = Directory.systemTemp.createTempSync('nota_hive_');
    Hive.init(tmp.path);
  }

  // Initialize Indonesian locale for DateFormat/NumberFormat
  try {
    await initializeDateFormatting('id_ID', null);
    Intl.defaultLocale = 'id_ID';
  } catch (_) {}
  Hive.registerAdapter(NotaAdapter());
  Hive.registerAdapter(NotaItemAdapter());
  await HiveService.instance.init();

  runApp(const NotaApp());
}

class NotaApp extends StatelessWidget {
  const NotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Cetak Nota',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/input': (_) => const NotaFormPage(),
        '/rekap': (_) => const RecapPage(),
        '/rekap-bulanan': (_) => const RecapMonthPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == NotaDetailPage.routeName) {
          final nota = settings.arguments as Nota;
          return MaterialPageRoute(
              builder: (_) => NotaDetailPage(nota: nota));
        }
        return null;
      },
    );
  }
}
