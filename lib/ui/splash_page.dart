import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    final auth = AuthService.instance;
    final loggedIn = await auth.isLoggedIn();
    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final biometricsEnabled = await auth.isBiometricEnabled();
    if (!mounted) return;

    if (biometricsEnabled) {
      final canUseBiometric = await auth.isBiometricAvailable();
      if (!canUseBiometric) {
        await auth.setBiometricEnabled(false);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      final success = await auth.authenticate(reason: 'Gunakan biometrik untuk membuka aplikasi');
      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primary.withOpacity(0.16),
              color.primaryContainer.withOpacity(0.32)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.transparent,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 76,
                  height: 76,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aplikasi Cetak Nota',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Service Microwave • Denpasar',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
