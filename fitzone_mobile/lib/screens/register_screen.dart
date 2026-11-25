import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../widgets/success_check_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _edadCtrl = TextEditingController(text: '24');
  final _pesoCtrl = TextEditingController(text: '70');
  final _alturaCtrl = TextEditingController(text: '172');
  String _objetivo = 'mantener';
  String _genero = 'hombre';
  bool _obscure = true;
  String? _inlineError;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _edadCtrl.dispose();
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      {
        'nombre': _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'contrasena': _passCtrl.text,
        'edad': int.tryParse(_edadCtrl.text) ?? 24,
        'peso': double.tryParse(_pesoCtrl.text) ?? 70.0,
        'altura': int.tryParse(_alturaCtrl.text) ?? 172,
        'objetivo': _objetivo,
        'genero': _genero,
        'nivelActividad': 'Moderado',
      },
      deferNavigation: true,
    );

    if (!mounted) return;
    if (ok) {
      await SuccessCheckDialog.show(
        context,
        title: 'Cuenta creada',
        subtitle: 'Bienvenido a FitZone Fitness Club, ${_nombreCtrl.text.trim()}.',
        duration: const Duration(milliseconds: 650),
      );

      if (!mounted) return;
      Navigator.pop(context);
      auth.commitPendingSession();

      FitZoneApp.messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.cardElevated,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Registro completado. Bienvenido, ${_nombreCtrl.text.trim()}.',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
    } else {
      final msg = auth.error ?? 'No se pudo completar el registro. Verifica tus datos.';
      setState(() => _inlineError = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderSubtle),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 18, height: 2, color: AppTheme.primaryCrimson),
                  const SizedBox(width: 8),
                  const Text(
                    'NUEVO MIEMBRO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Únete a FitZone.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.3),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completa tu perfil para activar tus clases y seguimiento personalizado.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45),
              ),
              if (_inlineError != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryCrimson.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    _inlineError!,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _fieldLabel('NOMBRE Y APELLIDO'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(hintText: 'Nombre'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(hintText: 'Apellido'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _fieldLabel('CORREO ELECTRÓNICO'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'tucorreo@ejemplo.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 19),
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 18),
              _fieldLabel('CONTRASEÑA'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 20),
              _fieldLabel('MEDIDAS INICIALES'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _edadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Edad'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _pesoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _alturaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Altura (cm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _genero,
                      decoration: const InputDecoration(labelText: 'Género'),
                      items: const [
                        DropdownMenuItem(value: 'hombre', child: Text('Hombre')),
                        DropdownMenuItem(value: 'mujer', child: Text('Mujer')),
                      ],
                      onChanged: (v) => setState(() => _genero = v ?? 'hombre'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _objetivo,
                      decoration: const InputDecoration(labelText: 'Objetivo'),
                      items: const [
                        DropdownMenuItem(value: 'bajar_peso', child: Text('Bajar peso')),
                        DropdownMenuItem(value: 'ganar_musculo', child: Text('Músculo')),
                        DropdownMenuItem(value: 'mantener', child: Text('Mantener')),
                      ],
                      onChanged: (v) => setState(() => _objetivo = v ?? 'mantener'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CREAR MI CUENTA',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
