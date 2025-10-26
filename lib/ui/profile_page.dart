import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loadingBiometric = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _processingToggle = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final auth = AuthService.instance;
    final available = await auth.isBiometricAvailable();
    final enabled = await auth.isBiometricEnabled();

    if (enabled && !available) {
      await auth.setBiometricEnabled(false);
    }

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled && available;
      _loadingBiometric = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_processingToggle) return;
    setState(() => _processingToggle = true);
    final auth = AuthService.instance;
    var enabled = _biometricEnabled;

    if (value) {
      final success = await auth.authenticate(reason: 'Konfirmasi identitas Anda');
      if (success) {
        await auth.setBiometricEnabled(true);
        enabled = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login biometrik diaktifkan')),
          );
        }
      } else {
        enabled = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengaktifkan login biometrik')),
          );
        }
      }
    } else {
      await auth.setBiometricEnabled(false);
      enabled = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login biometrik dinonaktifkan')),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _processingToggle = false;
    });
  }

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
    if (ok == true && context.mounted) {
      await AuthService.instance.setLoggedIn(false);
      await AuthService.instance.setBiometricEnabled(false);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final canToggleBiometric = _biometricAvailable && !_loadingBiometric && !_processingToggle;
    final biometricSubtitle = _loadingBiometric
        ? 'Memeriksa ketersediaan biometrik...'
        : !_biometricAvailable
            ? 'Perangkat tidak mendukung biometrik'
            : _processingToggle
                ? 'Memproses...'
                : _biometricEnabled
                    ? 'Akan meminta wajah atau sidik jari saat membuka aplikasi'
                    : 'Aktifkan untuk login menggunakan wajah atau sidik jari';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.primary.withOpacity(0.05), color.tertiary.withOpacity(0.03)],
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
                    CircleAvatar(radius: 28, backgroundColor: color.primary, child: const Icon(Icons.person, color: Colors.white, size: 30)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('admin@local', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.color_lens_outlined),
                    title: const Text('Tema'),
                    subtitle: const Text('Mengikuti sistem'),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Login biometrik'),
                    subtitle: Text(biometricSubtitle),
                    value: _biometricAvailable && _biometricEnabled,
                    onChanged: canToggleBiometric ? (value) => _toggleBiometric(value) : null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Tentang Aplikasi'),
                    subtitle: const Text('Aplikasi Cetak Nota via Bluetooth'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.black.withOpacity(0.45)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
