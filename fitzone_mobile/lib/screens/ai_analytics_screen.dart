import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';

class AiAnalyticsScreen extends StatefulWidget {
  const AiAnalyticsScreen({super.key});

  @override
  State<AiAnalyticsScreen> createState() => _AiAnalyticsScreenState();
}

class _AiAnalyticsScreenState extends State<AiAnalyticsScreen> {
  double _frecuencia = 3;
  double _satisfaccion = 8;
  double _meses = 6;
  int _pagosAtrasados = 0;
  String _plan = 'mensual';
  bool _asistioUltimaSemana = true;
  bool _usaEntrenador = false;
  bool _clasesGrupales = true;
  bool _lesiones = false;

  Future<void> _predictMe() async {
    final user = context.read<AuthProvider>().user;
    await context.read<GymProvider>().runIndividualPrediction({
      'nombre': user?.nombreCompleto ?? 'Usuario FitZone',
      'correo': user?.correo ?? '',
      'edad': user?.edad ?? 26,
      'genero': user?.genero ?? 'hombre',
      'frecuencia_semanal': _frecuencia.round(),
      'tiempo_membresia_meses': _meses.round(),
      'objetivo': user?.objetivo ?? 'mantener',
      'plan_membresia': _plan,
      'ha_asistido_ultima_semana': _asistioUltimaSemana ? 'si' : 'no',
      'usa_entrenador_personal': _usaEntrenador ? 'si' : 'no',
      'asiste_clases_grupales': _clasesGrupales ? 'si' : 'no',
      'pagos_atrasados': _pagosAtrasados,
      'satisfaccion_servicio': _satisfaccion.round(),
      'lesiones_recientes': _lesiones ? 'si' : 'no',
      'peso_actual': user?.peso ?? 72.0,
      'cambio_peso_mensual': -0.5,
      'tiene_descuento': 'no',
      'ingresos_mensuales': 4500,
    });
  }

  String _friendlyLevel(String risk) {
    if (risk == 'BAJO') return 'EXCELENTE';
    if (risk == 'MEDIO') return 'MODERADO';
    return 'POR MEJORAR';
  }

  Color _levelColor(String risk) {
    if (risk == 'ALTO') return AppTheme.primaryCrimson;
    if (risk == 'MEDIO') return AppTheme.warningAmber;
    return AppTheme.successGreen;
  }

  String _friendlyProfile(String rawSegment) {
    if (rawSegment.toLowerCase().contains('riesgo')) return 'Ritmo inicial';
    if (rawSegment.toLowerCase().contains('casual')) return 'Entrenamiento regular';
    return 'Atleta comprometido';
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final pred = gym.individualPrediction;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const Text(
          'Tu diagnóstico de constancia',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cuéntanos cómo va tu semana para calcular tu nivel de disciplina y armar un plan de mejora a tu medida.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sliderLabel('Días de entrenamiento por semana', '${_frecuencia.round()} días'),
                Slider(
                  value: _frecuencia,
                  min: 0,
                  max: 7,
                  divisions: 7,
                  activeColor: AppTheme.primaryCrimson,
                  inactiveColor: AppTheme.borderSubtle,
                  onChanged: (v) => setState(() => _frecuencia = v),
                ),
                _sliderLabel('¿Cómo calificas tu experiencia?', '${_satisfaccion.round()}/10'),
                Slider(
                  value: _satisfaccion,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: AppTheme.primaryCrimson,
                  inactiveColor: AppTheme.borderSubtle,
                  onChanged: (v) => setState(() => _satisfaccion = v),
                ),
                _sliderLabel('Tiempo entrenando en FitZone', '${_meses.round()} meses'),
                Slider(
                  value: _meses,
                  min: 1,
                  max: 36,
                  divisions: 35,
                  activeColor: AppTheme.primaryCrimson,
                  inactiveColor: AppTheme.borderSubtle,
                  onChanged: (v) => setState(() => _meses = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _plan,
                        decoration: const InputDecoration(labelText: 'Tu plan', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                          DropdownMenuItem(value: 'trimestral', child: Text('Trimestral')),
                          DropdownMenuItem(value: 'anual', child: Text('Anual')),
                        ],
                        onChanged: (v) => setState(() => _plan = v ?? 'mensual'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _pagosAtrasados,
                        decoration: const InputDecoration(labelText: 'Estado de pagos', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Al día')),
                          DropdownMenuItem(value: 1, child: Text('1 mes')),
                          DropdownMenuItem(value: 2, child: Text('2 meses')),
                          DropdownMenuItem(value: 3, child: Text('3+ meses')),
                        ],
                        onChanged: (v) => setState(() => _pagosAtrasados = v ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Entrené esta semana'),
                      selected: _asistioUltimaSemana,
                      selectedColor: AppTheme.primaryMuted,
                      checkmarkColor: AppTheme.primaryCrimson,
                      onSelected: (v) => setState(() => _asistioUltimaSemana = v),
                    ),
                    FilterChip(
                      label: const Text('Clases grupales'),
                      selected: _clasesGrupales,
                      selectedColor: AppTheme.primaryMuted,
                      checkmarkColor: AppTheme.primaryCrimson,
                      onSelected: (v) => setState(() => _clasesGrupales = v),
                    ),
                    FilterChip(
                      label: const Text('Entrenador personal'),
                      selected: _usaEntrenador,
                      selectedColor: AppTheme.primaryMuted,
                      checkmarkColor: AppTheme.primaryCrimson,
                      onSelected: (v) => setState(() => _usaEntrenador = v),
                    ),
                    FilterChip(
                      label: const Text('Lesión reciente'),
                      selected: _lesiones,
                      selectedColor: AppTheme.primaryMuted,
                      checkmarkColor: AppTheme.primaryCrimson,
                      onSelected: (v) => setState(() => _lesiones = v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: gym.loadingAi ? null : _predictMe,
                    child: Text(gym.loadingAi ? 'Analizando tu rutina...' : 'Evaluar mi constancia'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (pred != null) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (_) {
              final consistencyPct = (100.0 - pred.probabilidadPorcentaje).clamp(0.0, 100.0);
              final color = _levelColor(pred.nivelRiesgo);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tu resultado',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              _friendlyLevel(pred.nivelRiesgo),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Índice de constancia',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${consistencyPct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(10),
                                border: AppTheme.neonBorder,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tu ritmo actual',
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  const SizedBox(height: 3),
                                  Text(
                                    _friendlyProfile(pred.segmento),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (consistencyPct / 100.0).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppTheme.borderSubtle,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Plan de acción recomendado',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      const SizedBox(height: 10),
                      ...pred.recomendaciones.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_rounded, color: AppTheme.primaryCrimson, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppTheme.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _sliderLabel(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
