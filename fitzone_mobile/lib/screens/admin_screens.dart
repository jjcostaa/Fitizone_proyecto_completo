import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/gym_provider.dart';
import '../widgets/ml_charts_section.dart';

// ==================== TAB 1: DASHBOARD ADMIN + PROMOS ====================
class AdminDashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const AdminDashboardTab({super.key, required this.onNavigateTab});

  Future<void> _showCreatePromoDialog(BuildContext context) async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final inicioCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final finCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30))),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Publicar promoción', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inicioCtrl,
                      decoration: const InputDecoration(labelText: 'Inicio', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: finCtrl,
                      decoration: const InputDecoration(labelText: 'Fin', isDense: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (tituloCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final err = await context.read<GymProvider>().crearAnuncioAdmin(
                    titulo: tituloCtrl.text.trim(),
                    descripcion: descCtrl.text.trim(),
                    fechaInicio: inicioCtrl.text.trim(),
                    fechaFin: finCtrl.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Promoción publicada.')),
                );
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final stats = gym.adminStats ?? {};
    final totalUsuarios = (stats['usuarios'] as num?)?.toInt() ??
        gym.todosUsuarios.where((u) => u.rol.toUpperCase() == 'USUARIO' || u.rol.toUpperCase() == 'USER').length;
    final totalEntrenadores = (stats['entrenadores'] as num?)?.toInt() ??
        gym.todosUsuarios.where((u) => u.isEntrenador).length;
    final totalClases = (stats['clases'] as num?)?.toInt() ?? gym.todasClases.length;
    final ingresos = (stats['ingresosMes'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      color: AppTheme.primaryCrimson,
      onRefresh: () => gym.loadAdminDashboard(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          // Tarjeta ejecutiva Admin con textura sutil de gimnasio y borde rojo neón
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF171214),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderSubtle, width: 1),
              boxShadow: AppTheme.neonBoxShadow,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.20,
                    child: Image.asset(
                      'assets/images/login_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF221116).withValues(alpha: 0.88),
                          const Color(0xFF111115).withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 3, color: AppTheme.primaryCrimson),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryCrimson, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'CENTRO DE CONTROL',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCrimson,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ingresos acumulados',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,###').format(ingresos)} COP',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onNavigateTab(2),
                              icon: const Icon(Icons.analytics_rounded, size: 17),
                              label: const Text('Ver riesgos'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onNavigateTab(3),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.7),
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 17),
                              label: const Text('Horarios'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // KPIs con fondos diferenciados en degradado oscuro y borde rojo neón
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Miembros',
                  '$totalUsuarios',
                  Icons.people_alt_rounded,
                  bgStart: const Color(0xFF34111A),
                  bgEnd: const Color(0xFF171216),
                  accent: const Color(0xFFFF4D67),
                  onTap: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  'Coaches',
                  '$totalEntrenadores',
                  Icons.sports_rounded,
                  bgStart: const Color(0xFF32220E),
                  bgEnd: const Color(0xFF181512),
                  accent: const Color(0xFFF5A623),
                  onTap: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  'Clases',
                  '$totalClases',
                  Icons.fitness_center_rounded,
                  bgStart: const Color(0xFF10233C),
                  bgEnd: const Color(0xFF12161E),
                  accent: const Color(0xFF38BDF8),
                  onTap: () => onNavigateTab(3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Promociones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.primaryCrimson, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text(
                    'Promociones activas',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showCreatePromoDialog(context),
                icon: const Icon(Icons.add_rounded, color: AppTheme.primaryCrimson, size: 18),
                label: const Text(
                  'Nueva',
                  style: TextStyle(color: AppTheme.primaryCrimson, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (gym.anuncios.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No hay promociones publicadas. Toca "Nueva" para crear una oferta visible para los miembros.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            )
          else
            ...gym.anuncios.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${a.descripcion}\n${a.fechaInicio} — ${a.fechaFin}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: () async {
                        final err = await gym.eliminarAnuncioAdmin(a.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err ?? 'Promoción eliminada.')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String label,
    String val,
    IconData icon, {
    required Color bgStart,
    required Color bgEnd,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [bgStart, bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: AppTheme.neonBorder,
            boxShadow: AppTheme.neonBoxShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: accent.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TAB 2: GESTIÓN DE USUARIOS ====================
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _roleFilter = 'TODOS';
  String _query = '';

  Future<void> _showAddUserDialog() async {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'USUARIO';
    String? dialogError;
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: const Text('Nuevo usuario', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryCrimson.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido (opcional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'USUARIO', child: Text('Miembro (Usuario)')),
                    DropdownMenuItem(value: 'ENTRENADOR', child: Text('Entrenador (Coach)')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  onChanged: submitting ? null : (v) => setModalState(() => rol = v ?? 'USUARIO'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final nombre = nombreCtrl.text.trim();
                      final correo = correoCtrl.text.trim().toLowerCase();
                      final pass = passCtrl.text;

                      if (nombre.isEmpty) {
                        setModalState(() => dialogError = 'Ingresa el nombre del usuario.');
                        return;
                      }
                      if (!correo.contains('@') || !correo.contains('.')) {
                        setModalState(() => dialogError = 'Ingresa un correo electrónico válido.');
                        return;
                      }
                      if (pass.length < 6) {
                        setModalState(() => dialogError = 'La contraseña debe tener mínimo 6 caracteres.');
                        return;
                      }

                      setModalState(() {
                        dialogError = null;
                        submitting = true;
                      });

                      final err = await context.read<GymProvider>().crearUsuarioDesdeAdmin({
                        'nombre': nombre,
                        'apellido': apellidoCtrl.text.trim(),
                        'correo': correo,
                        'contrasena': pass,
                        'rol': rol,
                        'verificado': true,
                      });

                      if (!ctx.mounted) return;
                      if (err == null) {
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 19),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('Usuario $correo guardado en la base de datos ($rol).')),
                                  ],
                                ),
                              ),
                            );
                        }
                      } else {
                        setModalState(() {
                          submitting = false;
                          dialogError = err;
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final filtered = gym.todosUsuarios.where((u) {
      final matchesRole = _roleFilter == 'TODOS' ||
          u.rol.toUpperCase() == _roleFilter ||
          (_roleFilter == 'USUARIO' && u.rol.toUpperCase() == 'USER');
      final matchesQuery = _query.trim().isEmpty ||
          u.nombreCompleto.toLowerCase().contains(_query.toLowerCase()) ||
          u.correo.toLowerCase().contains(_query.toLowerCase());
      return matchesRole && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppTheme.primaryCrimson,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Nuevo usuario', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o correo...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['TODOS', 'USUARIO', 'ENTRENADOR', 'ADMIN'].map((r) {
                      final selected = _roleFilter == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r == 'TODOS' ? 'Todos (${gym.todosUsuarios.length})' : r),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _roleFilter = r),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryCrimson,
              onRefresh: () => gym.loadAdminDashboard(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
                itemCount: filtered.length,
                itemBuilder: (_, idx) {
                  final u = filtered[idx];
                  final isAdmin = u.isAdmin;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isAdmin ? AppTheme.primaryMuted : AppTheme.cardElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (u.nombre.isNotEmpty ? u.nombre[0] : 'U').toUpperCase(),
                            style: TextStyle(
                              color: isAdmin ? AppTheme.primaryCrimson : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(u.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        subtitle: Text(u.correo, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppTheme.primaryMuted : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isAdmin
                                  ? AppTheme.primaryCrimson.withValues(alpha: 0.45)
                                  : AppTheme.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            u.rol.toUpperCase(),
                            style: TextStyle(
                              color: isAdmin ? AppTheme.primaryCrimson : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 3: PREDICCIONES DE CANCELACIÓN IA (ADMIN) ====================
class AdminPredictionsTab extends StatefulWidget {
  const AdminPredictionsTab({super.key});

  @override
  State<AdminPredictionsTab> createState() => _AdminPredictionsTabState();
}

class _AdminPredictionsTabState extends State<AdminPredictionsTab> {
  String _riskFilter = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymProvider>().loadMlMetrics(loadAdminBundle: true);
    });
  }

  Color _riskColor(String risk) {
    if (risk == 'ALTO') return AppTheme.primaryCrimson;
    if (risk == 'MEDIO') return AppTheme.warningAmber;
    return AppTheme.successGreen;
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final report = gym.mlMetrics;
    final preds = gym.batchPredictions.where((p) {
      if (_riskFilter == 'TODOS') return true;
      return p.nivelRiesgo == _riskFilter;
    }).toList();

    final summary = gym.batchSummary ?? {};

    return RefreshIndicator(
      color: AppTheme.primaryCrimson,
      onRefresh: () => gym.loadMlMetrics(loadAdminBundle: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          const Text(
            'Radar de retención',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Miembros ordenados según probabilidad estimada de cancelación.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _riskStat('Riesgo alto', '${summary['alto'] ?? '-'}', AppTheme.primaryCrimson)),
              const SizedBox(width: 10),
              Expanded(child: _riskStat('Riesgo medio', '${summary['medio'] ?? '-'}', AppTheme.warningAmber)),
              const SizedBox(width: 10),
              Expanded(child: _riskStat('Riesgo bajo', '${summary['bajo'] ?? '-'}', AppTheme.successGreen)),
            ],
          ),
          const SizedBox(height: 14),

          // Gráficas interactivas de Minería de Datos II (fl_chart)
          MlChartsSection(
            riskSummary: summary,
            report: report,
          ),

          const SizedBox(height: 18),
          const Text(
            'Detalle por miembro',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['TODOS', 'ALTO', 'MEDIO', 'BAJO'].map((r) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r == 'TODOS' ? 'Todos (${gym.batchPredictions.length})' : r),
                    selected: _riskFilter == r,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _riskFilter = r),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          if (gym.loadingAi)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryCrimson)),
            )
          else
            ...preds.take(25).map((p) {
              final rc = _riskColor(p.nivelRiesgo);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rc.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        '${p.probabilidadPorcentaje.toStringAsFixed(0)}%',
                        style: TextStyle(color: rc, fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    ),
                    title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(
                      '${p.segmento} · ${p.correo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Text(
                      p.nivelRiesgo,
                      style: TextStyle(color: rc, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _riskStat(String label, String val, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB 4: OPTIMIZACIÓN DE INSTRUCTORES (ADMIN) ====================
class AdminOptimizationTab extends StatelessWidget {
  const AdminOptimizationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final opt = gym.optimizationResult;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const Text(
          'Asignación óptima de horarios',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Calcula la distribución ideal de instructores y disciplinas para optimizar el costo operativo.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: gym.loadingAi ? null : () => gym.runOptimization(),
            child: Text(gym.loadingAi ? 'Calculando...' : 'Generar plan óptimo'),
          ),
        ),
        if (opt != null) ...[
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Costo operativo mínimo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                      SizedBox(height: 2),
                      Text('Asignación balanceada', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
                    ],
                  ),
                  Text(
                    '\$${opt.costoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...opt.asignaciones.map((inst) {
            final ratio = inst.capacidad > 0 ? (inst.horasUtilizadas / inst.capacidad).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(inst.instructor, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                          Text(
                            '${inst.horasUtilizadas}h / ${inst.capacidad}h',
                            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: AppTheme.borderSubtle,
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (inst.clases.isEmpty)
                        const Text('Sin clases asignadas', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
                      else
                        ...inst.clases.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${c['clase']} (${c['duracion']}h)',
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                                Text(
                                  '\$${(c['costo'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
