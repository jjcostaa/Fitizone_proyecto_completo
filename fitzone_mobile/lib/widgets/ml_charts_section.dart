import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/ai_models.dart';

class MlChartsSection extends StatelessWidget {
  final Map<String, dynamic> riskSummary;
  final MlMetricsReport? report;

  const MlChartsSection({
    super.key,
    required this.riskSummary,
    required this.report,
  });

  static const Color _blueElectric = Color(0xFF38BDF8);
  static const Color _amberGold = Color(0xFFF5A623);

  String _prettyVar(String raw) {
    const map = {
      'satisfaccion_servicio': 'Satisfacción',
      'frecuencia_semanal': 'Frecuencia semanal',
      'ha_asistido_ultima_semana_si': 'Asistió última sem (Sí)',
      'ha_asistido_ultima_semana_no': 'Asistió última sem (No)',
      'ingresos_mensuales': 'Ingresos mensuales',
      'pagos_atrasados': 'Pagos atrasados',
      'tiempo_membresia_meses': 'Antigüedad (meses)',
      'cambio_peso_mensual': 'Cambio de peso',
    };
    return map[raw] ?? raw.replaceAll('_', ' ');
  }

  String _shortModel(String name) {
    if (name.toLowerCase().contains('random')) return 'Random\nForest';
    if (name.toLowerCase().contains('gradient')) return 'Gradient\nBoost';
    if (name.toLowerCase().contains('mlp') || name.toLowerCase().contains('neuronal')) return 'Red\nMLP';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final alto = (riskSummary['alto'] as num?)?.toInt() ?? 0;
    final medio = (riskSummary['medio'] as num?)?.toInt() ?? 0;
    final bajo = (riskSummary['bajo'] as num?)?.toInt() ?? 0;
    final totalRisk = alto + medio + bajo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Gráfica Circular (Dona) — Distribución de Riesgo
        if (totalRisk > 0) ...[
          _buildRiskDonutCard(alto, medio, bajo, totalRisk),
          const SizedBox(height: 14),
        ],

        if (report != null) ...[
          // 2. Gráfica de Barras — Comparativa de Modelos ML (Python)
          if (report!.comparacion.isNotEmpty) ...[
            _buildModelsBarCard(report!),
            const SizedBox(height: 14),
          ],

          // 3. Gráfica de Líneas — Curvas ROC-AUC
          if (report!.comparacion.isNotEmpty) ...[
            _buildRocCurveCard(report!),
            const SizedBox(height: 14),
          ],

          // 4. Segmentación K-Means (Dona)
          if (report!.segmentos.isNotEmpty) ...[
            _buildKMeansCard(report!),
            const SizedBox(height: 14),
          ],

          // 5. Importancia de Variables + Matriz de Confusión
          if (report!.importanciaVariables.isNotEmpty) ...[
            _buildFeatureImportanceCard(report!),
            const SizedBox(height: 14),
          ],

          _buildConfusionMatrixCard(report!),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle, IconData icon, Color accent) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRiskDonutCard(int alto, int medio, int bajo, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Distribución de riesgo de abandono',
              'Clasificación en tiempo real · Modelo predictivo Python',
              Icons.donut_large_rounded,
              AppTheme.neonRed,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 42,
                            sections: [
                              if (alto > 0)
                                PieChartSectionData(
                                  value: alto.toDouble(),
                                  color: AppTheme.neonRed,
                                  radius: 28,
                                  title: '${(alto * 100 / total).round()}%',
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              if (medio > 0)
                                PieChartSectionData(
                                  value: medio.toDouble(),
                                  color: _amberGold,
                                  radius: 28,
                                  title: '${(medio * 100 / total).round()}%',
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
                                ),
                              if (bajo > 0)
                                PieChartSectionData(
                                  value: bajo.toDouble(),
                                  color: AppTheme.successGreen,
                                  radius: 28,
                                  title: '${(bajo * 100 / total).round()}%',
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const Text('Analizados', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendDot(AppTheme.neonRed, 'Alto: $alto (${(alto * 100 / total).toStringAsFixed(0)}%)'),
                        const SizedBox(height: 10),
                        _legendDot(_amberGold, 'Medio: $medio (${(medio * 100 / total).toStringAsFixed(0)}%)'),
                        const SizedBox(height: 10),
                        _legendDot(AppTheme.successGreen, 'Bajo: $bajo (${(bajo * 100 / total).toStringAsFixed(0)}%)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsBarCard(MlMetricsReport report) {
    final models = report.comparacion;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Comparativa de modelos Python',
              'Ganador: ${report.modeloGanador} · ${report.totalRegistros} registros',
              Icons.bar_chart_rounded,
              _amberGold,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _legendDot(AppTheme.neonRed, 'Accuracy'),
                _legendDot(_amberGold, 'F1-Score'),
                _legendDot(_blueElectric, 'ROC-AUC'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 195,
              child: BarChart(
                BarChartData(
                  minY: 65,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.cardElevated,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        const metricNames = ['Accuracy', 'F1-Score', 'ROC-AUC'];
                        return BarTooltipItem(
                          '${metricNames[rodIndex]}\n${rod.toY.toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.borderSubtle, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 10,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}%',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= models.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _shortModel(models[idx].modelo),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(models.length, (i) {
                    final m = models[i];
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: (m.accuracy * 100).clamp(65, 100),
                          color: AppTheme.neonRed,
                          width: 11,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: (m.f1Score * 100).clamp(65, 100),
                          color: _amberGold,
                          width: 11,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: (m.rocAuc * 100).clamp(65, 100),
                          color: _blueElectric,
                          width: 11,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRocCurveCard(MlMetricsReport report) {
    final models = report.comparacion;
    final palette = [AppTheme.neonRed, _amberGold, _blueElectric];

    final lines = <LineChartBarData>[
      // Diagonal de referencia (azar = 0.5)
      LineChartBarData(
        spots: const [FlSpot(0, 0), FlSpot(1, 1)],
        isCurved: false,
        color: AppTheme.textMuted.withValues(alpha: 0.55),
        barWidth: 1.3,
        dashArray: [6, 4],
        dotData: const FlDotData(show: false),
      ),
    ];

    for (var i = 0; i < models.length; i++) {
      final m = models[i];
      final pts = m.curvaRoc.isNotEmpty
          ? m.curvaRoc.map((p) => FlSpot(p.fpr, p.tpr)).toList()
          : [
              const FlSpot(0, 0),
              FlSpot(0.12, m.recall.clamp(0.1, 0.99)),
              const FlSpot(1, 1),
            ];
      lines.add(
        LineChartBarData(
          spots: pts,
          isCurved: true,
          curveSmoothness: 0.2,
          color: palette[i % palette.length],
          barWidth: i == 0 ? 2.8 : 2.0,
          dotData: const FlDotData(show: false),
          belowBarData: i == 0
              ? BarAreaData(show: true, color: AppTheme.neonRed.withValues(alpha: 0.12))
              : BarAreaData(show: false),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Curvas ROC-AUC',
              'Capacidad discriminativa entre permanencia y cancelación',
              Icons.show_chart_rounded,
              _blueElectric,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: List.generate(
                models.length,
                (i) => _legendDot(
                  palette[i % palette.length],
                  '${models[i].modelo.split(' ').first} (${(models[i].rocAuc * 100).toStringAsFixed(1)}%)',
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 185,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 1,
                  minY: 0,
                  maxY: 1,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 0.25,
                    verticalInterval: 0.25,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.borderSubtle, strokeWidth: 0.8),
                    getDrawingVerticalLine: (_) => const FlLine(color: AppTheme.borderSubtle, strokeWidth: 0.8),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppTheme.borderSubtle, width: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 0.25,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 0.25,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: lines,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKMeansCard(MlMetricsReport report) {
    final segs = report.segmentos;
    final colors = [AppTheme.successGreen, _amberGold, AppTheme.neonRed];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Segmentación K-Means (k=3)',
              'Clustering no supervisado · Silhouette ${report.silhouetteScore.toStringAsFixed(4)}',
              Icons.hub_rounded,
              AppTheme.successGreen,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 155,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 34,
                        sections: List.generate(segs.length, (i) {
                          final s = segs[i];
                          final c = colors[i % colors.length];
                          return PieChartSectionData(
                            value: s.cantidad.toDouble(),
                            color: c,
                            radius: 26,
                            title: '${s.porcentaje.toStringAsFixed(0)}%',
                            titleStyle: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: c == _amberGold ? Colors.black : Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(segs.length, (i) {
                        final s = segs[i];
                        final c = colors[i % colors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _legendDot(c, '${s.segmento} (${s.cantidad})'),
                              Padding(
                                padding: const EdgeInsets.only(left: 15, top: 2),
                                child: Text(
                                  'Frec ${s.frecuenciaPromedio}d/sem · Churn ${s.tasaCancelacion.toStringAsFixed(0)}%',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureImportanceCard(MlMetricsReport report) {
    final vars = report.importanciaVariables.take(6).toList();
    final maxImp = vars.map((v) => v.importancia).fold<double>(0.01, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Variables más influyentes',
              'Peso en la predicción de deserción (Random Forest)',
              Icons.tune_rounded,
              AppTheme.neonRed,
            ),
            const SizedBox(height: 14),
            ...vars.map((v) {
              final pct = (v.importancia * 100).toStringAsFixed(1);
              final ratio = (v.importancia / maxImp).clamp(0.05, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_prettyVar(v.variable), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.neonRed)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceDark,
                        color: AppTheme.neonRed,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildConfusionMatrixCard(MlMetricsReport report) {
    final winner = report.comparacion.where((m) => m.modelo == report.modeloGanador).firstOrNull ??
        (report.comparacion.isNotEmpty ? report.comparacion.first : null);
    final cm = winner?.matrizConfusion;
    if (cm == null) return const SizedBox.shrink();

    Widget cell(String title, int val, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Column(
            children: [
              Text('$val', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Matriz de confusión',
              'Validación sobre conjunto de prueba (${report.modeloGanador})',
              Icons.grid_view_rounded,
              _blueElectric,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                cell('Verdaderos Neg. (VN)', cm.tn, AppTheme.successGreen),
                const SizedBox(width: 10),
                cell('Falsos Pos. (FP)', cm.fp, _amberGold),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                cell('Falsos Neg. (FN)', cm.fn, AppTheme.neonRed),
                const SizedBox(width: 10),
                cell('Verdaderos Pos. (VP)', cm.tp, _blueElectric),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
