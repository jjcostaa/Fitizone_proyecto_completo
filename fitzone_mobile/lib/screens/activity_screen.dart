import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/notification_service.dart';
import '../services/pedometer_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  bool _savingImc = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _pesoCtrl.text = user.peso > 0 ? user.peso.toString() : '70';
      _alturaCtrl.text = user.altura > 0 ? user.altura.toString() : '170';
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    super.dispose();
  }

  double get _previewImc {
    final p = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    final h = double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 0;
    if (p <= 0 || h <= 0) return 0;
    final m = h / 100.0;
    return p / (m * m);
  }

  String _imcCategory(double imc) {
    if (imc <= 0) return 'Ingresa tus datos';
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Saludable';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _imcColor(double imc) {
    if (imc <= 0) return AppTheme.textSecondary;
    if (imc < 18.5) return AppTheme.textSecondary;
    if (imc < 25) return AppTheme.successGreen;
    if (imc < 30) return AppTheme.warningAmber;
    return AppTheme.primaryCrimson;
  }

  Future<void> _saveImc() async {
    final auth = context.read<AuthProvider>();
    final gym = context.read<GymProvider>();
    final user = auth.user;
    if (user == null) return;

    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    final altura = double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() => _savingImc = true);
    final err = await gym.registrarImc(user.id, peso, altura);
    if (err == null) {
      await auth.refreshProfile();
    }
    setState(() => _savingImc = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Registro de IMC guardado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pedo = context.watch<PedometerService>();
    final user = auth.user;
    final historial = user?.historialIMC.reversed.toList() ?? [];
    final currentImc = _previewImc;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        // ==================== PODÓMETRO ====================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actividad de hoy',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Contador de pasos por sensor',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: pedo.isTracking ? AppTheme.successGreen : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pedo.isTracking ? 'Activo' : 'En pausa',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 172,
                  height: 172,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: pedo.progress,
                        strokeWidth: 9,
                        backgroundColor: AppTheme.borderSubtle,
                        color: AppTheme.primaryCrimson,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${pedo.stepsToday}',
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'de ${pedo.dailyGoal} pasos',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: AppTheme.neonBorder,
                    boxShadow: AppTheme.neonBoxShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCol('${pedo.distanceKm.toStringAsFixed(2)} km', 'Distancia', Icons.route_rounded),
                      Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                      _statCol('${pedo.caloriesKcal.toStringAsFixed(0)} kcal', 'Calorías', Icons.local_fire_department_rounded),
                      Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                      _statCol('${(pedo.progress * 100).toStringAsFixed(0)}%', 'Objetivo', Icons.flag_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (pedo.isTracking) {
                            pedo.stopTracking();
                          } else {
                            pedo.startTracking();
                          }
                        },
                        icon: Icon(pedo.isTracking ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 19),
                        label: Text(pedo.isTracking ? 'Pausar' : 'Reanudar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => pedo.addSimulatedSteps(100),
                      child: const Text('+100 pasos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ==================== RECORDATORIOS ====================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recordatorios de entrenamiento',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recibe alertas locales en tu dispositivo para mantener tu constancia.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await NotificationService().showInstantNotification(
                            id: 2001,
                            title: 'Hora de entrenar en FitZone',
                            body: 'Llevas ${pedo.stepsToday} pasos hoy. Mantén el ritmo.',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notificación enviada.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.notifications_none_rounded, size: 18),
                        label: const Text('Probar alerta'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await NotificationService().scheduleReminder(
                            id: 2002,
                            title: 'Sesión FitZone programada',
                            body: 'Tu próximo entrenamiento está por comenzar.',
                            delay: const Duration(seconds: 15),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recordatorio programado.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: const Text('Programar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ==================== CONTROL DE IMC ====================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Control de IMC',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    if (currentImc > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(6),
                          border: AppTheme.neonBorder,
                        ),
                        child: Text(
                          '${currentImc.toStringAsFixed(1)} · ${_imcCategory(currentImc)}',
                          style: TextStyle(
                            color: _imcColor(currentImc),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pesoCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _alturaCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Altura (cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 5, color: const Color(0xFF52525B))),
                      const SizedBox(width: 2),
                      Expanded(flex: 2, child: Container(height: 5, color: AppTheme.successGreen)),
                      const SizedBox(width: 2),
                      Expanded(child: Container(height: 5, color: AppTheme.warningAmber)),
                      const SizedBox(width: 2),
                      Expanded(child: Container(height: 5, color: AppTheme.primaryCrimson)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bajo', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    Text('Saludable', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    Text('Sobrepeso', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    Text('Obesidad', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingImc ? null : _saveImc,
                    child: Text(_savingImc ? 'Guardando...' : 'Guardar registro'),
                  ),
                ),
                if (historial.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  const SizedBox(height: 14),
                  const Text(
                    'Historial reciente',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  ...historial.take(5).map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: AppTheme.neonBorder,
                                ),
                                child: Text(
                                  item.imc.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: _imcColor(item.imc),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.categoria} · ${item.peso} kg',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy · HH:mm').format(item.fecha),
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCol(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 17, color: AppTheme.primaryCrimson),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
