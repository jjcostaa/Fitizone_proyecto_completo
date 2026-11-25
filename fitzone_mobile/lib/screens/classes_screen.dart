import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/gym_models.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/notification_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  bool _onlyMine = false;
  String _search = '';

  IconData _iconForClass(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('yoga') || lower.contains('pilates')) return Icons.self_improvement_rounded;
    if (lower.contains('spin') || lower.contains('ciclo')) return Icons.directions_bike_rounded;
    if (lower.contains('box')) return Icons.sports_mma_rounded;
    if (lower.contains('zumba') || lower.contains('baile')) return Icons.music_note_rounded;
    if (lower.contains('cross') || lower.contains('funcional')) return Icons.local_fire_department_rounded;
    return Icons.fitness_center_rounded;
  }

  Future<void> _showCreateClassDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Publicar clase', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (ej. Spinning Pro)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción y horario'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final err = await context.read<GymProvider>().crearClase(
                    user.id,
                    nameCtrl.text.trim(),
                    descCtrl.text.trim(),
                  );
              if (mounted) {
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

  Future<void> _scheduleClassReminder(ClaseModel clase) async {
    await NotificationService().scheduleReminder(
      id: clase.id.hashCode.abs() % 100000,
      title: 'Tu clase está por comenzar',
      body: '${clase.nombreClase} con ${clase.nombreEntrenador}.',
      delay: const Duration(seconds: 10),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recordatorio activado para "${clase.nombreClase}".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final gym = context.watch<GymProvider>();
    if (user == null) return const SizedBox.shrink();

    final baseList = _onlyMine ? gym.misClases : gym.todasClases;
    final list = _search.trim().isEmpty
        ? baseList
        : baseList
            .where((c) =>
                c.nombreClase.toLowerCase().contains(_search.toLowerCase()) ||
                c.nombreEntrenador.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: user.isEntrenador
          ? FloatingActionButton.extended(
              onPressed: _showCreateClassDialog,
              backgroundColor: AppTheme.primaryCrimson,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva clase'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar clase o entrenador...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: AppTheme.neonBorder,
                    boxShadow: AppTheme.neonBoxShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _segmentTab(
                          label: 'Explorar (${gym.todasClases.length})',
                          selected: !_onlyMine,
                          onTap: () => setState(() => _onlyMine = false),
                        ),
                      ),
                      Expanded(
                        child: _segmentTab(
                          label: 'Mis reservas (${gym.misClases.length})',
                          selected: _onlyMine,
                          onTap: () => setState(() => _onlyMine = true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryCrimson,
              onRefresh: () => gym.refreshClasses(user.id),
              child: gym.loadingClasses
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCrimson))
                  : list.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 76),
                            const Icon(Icons.fitness_center_rounded, size: 42, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _onlyMine
                                  ? 'Todavía no has reservado ninguna clase.'
                                  : 'No encontramos clases con ese criterio.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                          itemCount: list.length,
                          itemBuilder: (_, idx) {
                            final clase = list[idx];
                            final subscribed = gym.isSubscribed(clase.id);
                            return Padding(
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
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: subscribed ? AppTheme.primaryCrimson : AppTheme.primaryMuted,
                                              borderRadius: BorderRadius.circular(11),
                                            ),
                                            child: Icon(
                                              _iconForClass(clase.nombreClase),
                                              color: subscribed ? Colors.white : AppTheme.primaryCrimson,
                                              size: 21,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  clase.nombreClase,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  clase.nombreEntrenador,
                                                  style: const TextStyle(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 12.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (subscribed)
                                            IconButton(
                                              tooltip: 'Programar recordatorio',
                                              onPressed: () => _scheduleClassReminder(clase),
                                              icon: const Icon(
                                                Icons.notifications_none_rounded,
                                                color: AppTheme.textSecondary,
                                                size: 21,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        clase.descripcion,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13.5,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (subscribed)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 15, color: AppTheme.successGreen),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Cupo reservado',
                                                  style: TextStyle(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          subscribed
                                              ? OutlinedButton(
                                                  onPressed: () async {
                                                    final err = await gym.toggleSuscripcion(user.id, clase);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            err ?? 'Reserva cancelada para ${clase.nombreClase}.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppTheme.primaryCrimson,
                                                    side: BorderSide(
                                                        color: AppTheme.primaryCrimson.withValues(alpha: 0.45)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  ),
                                                  child: const Text('Cancelar'),
                                                )
                                              : ElevatedButton(
                                                  onPressed: () async {
                                                    final err = await gym.toggleSuscripcion(user.id, clase);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            err ?? 'Cupo reservado en ${clase.nombreClase}.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                  ),
                                                  child: const Text('Reservar'),
                                                ),
                                        ],
                                      ),
                                    ],
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

  Widget _segmentTab({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.cardElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
