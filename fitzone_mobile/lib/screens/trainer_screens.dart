import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/notification_service.dart';

// ==================== TAB 1: DASHBOARD ENTRENADOR ====================
class TrainerDashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const TrainerDashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final gym = context.watch<GymProvider>();
    if (user == null) return const SizedBox.shrink();

    final alumnos = gym.todosUsuarios
        .where((u) => u.rol.toUpperCase() == 'USUARIO' || u.rol.toUpperCase() == 'USER')
        .length;

    return RefreshIndicator(
      color: AppTheme.primaryCrimson,
      onRefresh: () => gym.loadTrainerDashboard(user),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          // Tarjeta Coach con textura sutil de gimnasio, barra de capacidad y borde rojo neón
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
                          const Color(0xFF211116).withValues(alpha: 0.88),
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
                              Icon(Icons.sports_rounded, color: AppTheme.primaryCrimson, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'PANEL DE ENTRENADOR',
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
                              'COACH',
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
                      const SizedBox(height: 14),
                      Text(
                        user.nombreCompleto,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 23, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tienes ${gym.clasesEntrenador.length} de 5 clases activas publicadas.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (gym.clasesEntrenador.length / 5.0).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onNavigateTab(1),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text('Gestionar clases'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () async {
                              await NotificationService().showInstantNotification(
                                id: 3001,
                                title: 'Agenda Coach FitZone',
                                body: 'Tienes ${gym.clasesEntrenador.length} clases programadas.',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Recordatorio de agenda enviado.')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.7),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            child: const Icon(Icons.notifications_active_outlined, size: 20, color: AppTheme.textPrimary),
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

          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Mis clases',
                  '${gym.clasesEntrenador.length}/5',
                  Icons.fitness_center_rounded,
                  onTap: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Alumnos activos',
                  '$alumnos',
                  Icons.groups_rounded,
                  onTap: () => onNavigateTab(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.primaryCrimson, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Mis clases publicadas', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                ],
              ),
              TextButton(
                onPressed: () => onNavigateTab(1),
                child: const Text('Ver todas', style: TextStyle(color: AppTheme.primaryCrimson)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (gym.clasesEntrenador.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Aún no has creado clases. Ve a la pestaña Clases para publicar tu primera sesión.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
                ),
              ),
            )
          else
            ...gym.clasesEntrenador.take(4).map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.cardElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center_rounded, color: AppTheme.textPrimary, size: 19),
                        ),
                        title: Text(c.nombreClase, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        subtitle: Text(
                          c.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryCrimson, size: 19),
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TAB 2: GESTIÓN DE CLASES DEL ENTRENADOR ====================
class TrainerClassesTab extends StatelessWidget {
  const TrainerClassesTab({super.key});

  Future<void> _showCreateClassDialog(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Crear clase', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (ej. Crossfit Avanzado)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción, nivel y horario'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final err = await context.read<GymProvider>().crearClaseEntrenador(
                    user.id,
                    nameCtrl.text.trim(),
                    descCtrl.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Clase publicada correctamente.')),
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
    final user = context.watch<AuthProvider>().user;
    final gym = context.watch<GymProvider>();
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: gym.clasesEntrenador.length >= 5
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alcanzaste el máximo de 5 clases activas.')),
                );
              }
            : () => _showCreateClassDialog(context),
        backgroundColor: AppTheme.primaryCrimson,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Nueva clase', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryCrimson,
        onRefresh: () => gym.loadTrainerDashboard(user),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mis clases asignadas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(
                  '${gym.clasesEntrenador.length} / 5',
                  style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (gym.clasesEntrenador.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Aún no has publicado clases. Toca "Nueva clase" para crear la primera.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                  ),
                ),
              )
            else
              ...gym.clasesEntrenador.map(
                (clase) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardElevated,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fitness_center_rounded, color: AppTheme.textPrimary, size: 19),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  clase.nombreClase,
                                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar clase',
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary, size: 20),
                                onPressed: () async {
                                  final err = await gym.eliminarClaseEntrenador(user.id, clase.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err ?? 'Clase eliminada.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            clase.descripcion,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB 3: DIRECTORIO DE ALUMNOS ====================
class TrainerStudentsTab extends StatefulWidget {
  const TrainerStudentsTab({super.key});

  @override
  State<TrainerStudentsTab> createState() => _TrainerStudentsTabState();
}

class _TrainerStudentsTabState extends State<TrainerStudentsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final students = gym.todosUsuarios.where((u) {
      final isMember = u.rol.toUpperCase() == 'USUARIO' || u.rol.toUpperCase() == 'USER';
      final matches = _search.trim().isEmpty ||
          u.nombreCompleto.toLowerCase().contains(_search.toLowerCase()) ||
          u.correo.toLowerCase().contains(_search.toLowerCase());
      return isMember && matches;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Buscar alumno...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            itemCount: students.length,
            itemBuilder: (_, idx) {
              final s = students[idx];
              final lastImc = s.historialIMC.isNotEmpty ? s.historialIMC.last : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (s.nombre.isNotEmpty ? s.nombre[0] : 'A').toUpperCase(),
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(
                      '${s.edad} años · ${s.peso} kg · ${s.altura} cm',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: lastImc != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'IMC ${lastImc.imc.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                lastImc.categoria,
                                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
