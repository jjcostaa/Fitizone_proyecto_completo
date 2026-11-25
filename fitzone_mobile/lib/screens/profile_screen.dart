import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/pedometer_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _alturaCtrl;
  late final TextEditingController _goalCtrl;
  String _objetivo = 'mantener';
  bool _saving = false;
  int _versionTaps = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nombreCtrl = TextEditingController(text: user?.nombre ?? '');
    _apellidoCtrl = TextEditingController(text: user?.apellido ?? '');
    _pesoCtrl = TextEditingController(text: (user?.peso ?? 70).toString());
    _alturaCtrl = TextEditingController(text: (user?.altura ?? 170).toString());
    _goalCtrl = TextEditingController(text: context.read<PedometerService>().dailyGoal.toString());
    final rawObj = (user?.objetivo ?? 'mantener').toLowerCase();
    if (['bajar_peso', 'ganar_musculo', 'mantener'].contains(rawObj)) {
      _objetivo = rawObj;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isMember = user != null && !user.isAdmin && !user.isEntrenador;

    final updates = <String, dynamic>{
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
    };
    if (isMember) {
      updates['peso'] = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 70.0;
      updates['altura'] = int.tryParse(_alturaCtrl.text) ?? 170;
      updates['objetivo'] = _objetivo;
    }

    final ok = await auth.updateProfile(updates);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Perfil actualizado.' : 'No pudimos guardar los cambios.')),
      );
    }
  }

  Future<void> _openHiddenCloudConfig() async {
    final ctrl = TextEditingController(text: ApiConfig.baseUrl);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Entorno Cloud'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Endpoint Cloud'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setBaseUrl(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gym = context.watch<GymProvider>();
    final pedo = context.watch<PedometerService>();
    final user = auth.user;
    final isMember = user != null && !user.isAdmin && !user.isEntrenador;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderSubtle),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          if (user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCrimson,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user.nombre.isNotEmpty ? user.nombre[0] : 'F').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nombreCompleto,
                            style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(user.correo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(6),
                              border: AppTheme.neonBorder,
                            ),
                            child: Text(
                              user.rol.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Datos personales
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos personales', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _apellidoCtrl,
                          decoration: const InputDecoration(labelText: 'Apellido', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  if (isMember) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pesoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Peso (kg)', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _alturaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Altura (cm)', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _objetivo,
                      decoration: const InputDecoration(labelText: 'Objetivo', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'bajar_peso', child: Text('Bajar de peso')),
                        DropdownMenuItem(value: 'ganar_musculo', child: Text('Ganar masa muscular')),
                        DropdownMenuItem(value: 'mantener', child: Text('Mantenerme activo')),
                      ],
                      onChanged: (v) => setState(() => _objetivo = v ?? 'mantener'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Meta diaria de pasos (solo para miembros/usuarios, independiente por cuenta)
          if (isMember) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Meta diaria de pasos', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _goalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Pasos objetivo', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final g = int.tryParse(_goalCtrl.text) ?? 6000;
                            await pedo.setDailyGoal(g);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Meta diaria actualizada a $g pasos.')),
                              );
                            }
                          },
                          child: const Text('Actualizar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (gym.pagos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Historial de pagos', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...gym.pagos.take(4).map(
                          (p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.membresia, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(p.fecha),
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${NumberFormat('#,###').format(p.monto)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Datos sin conexión', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Caché local para consultar clases y perfil offline',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              trailing: TextButton(
                onPressed: () async {
                  await auth.cache.clearAllDataCacheOnly();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caché local limpiada.')),
                    );
                  }
                },
                child: const Text('Limpiar'),
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                gym.resetSessionState();
                pedo.resetSession();
                await auth.logout();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryCrimson,
                side: BorderSide(color: AppTheme.primaryCrimson.withValues(alpha: 0.55)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () {
                _versionTaps++;
                if (_versionTaps >= 5) {
                  _versionTaps = 0;
                  _openHiddenCloudConfig();
                }
              },
              child: const Text(
                'FitZone Fitness Club · v1.0.0',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
