import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  void _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _loading = false);
    if (_user.text == 'admin' && _pass.text == 'admin123') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username/password salah')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 380;
          final horizontalMargin = isCompact ? 16.0 : 24.0;
          final verticalPadding = isCompact ? 18.0 : 24.0;
          final radius = BorderRadius.circular(isCompact ? 12 : 14);

          InputDecoration decoration({
            String? label,
            IconData? prefix,
            Widget? suffix,
          }) {
            final theme = Theme.of(context);
            return InputDecoration(
              labelText: label,
              prefixIcon:
                  prefix != null
                      ? Icon(prefix, size: isCompact ? 18 : 20)
                      : null,
              suffixIcon: suffix,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 16,
                vertical: isCompact ? 12 : 14,
              ),
              border: OutlineInputBorder(borderRadius: radius),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: theme.dividerColor.withOpacity(0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.primary.withOpacity(0.12),
                  color.primaryContainer.withOpacity(0.24),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalMargin,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? double.infinity : 420,
                  ),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalMargin,
                        vertical: verticalPadding,
                      ),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: isCompact ? 24 : 28,
                                  backgroundColor: color.primary,
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: Colors.white,
                                    size: isCompact ? 24 : 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Aplikasi Cetak Nota',
                                        style: TextStyle(
                                          fontSize: isCompact ? 16 : 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Service Microwave • Denpasar',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: isCompact ? 12 : 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: isCompact ? 48 : 52,
                              child: TextFormField(
                                controller: _user,
                                decoration: decoration(
                                  label: 'Username',
                                  prefix: Icons.person_outline,
                                ),
                                style: TextStyle(fontSize: isCompact ? 14 : 16),
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Wajib'
                                            : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: isCompact ? 48 : 52,
                              child: TextFormField(
                                controller: _pass,
                                obscureText: _obscure,
                                decoration: decoration(
                                  label: 'Password',
                                  prefix: Icons.lock_outline,
                                  suffix: IconButton(
                                    onPressed:
                                        () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                style: TextStyle(fontSize: isCompact ? 14 : 16),
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Wajib'
                                            : null,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _loading ? null : _login,
                              icon:
                                  _loading
                                      ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.login),
                              label: const Text('Masuk'),
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(
                                  isCompact ? 44 : 50,
                                ),
                                textStyle: TextStyle(
                                  fontSize: isCompact ? 15 : 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'admin / admin123',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: isCompact ? 12 : 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
