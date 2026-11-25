import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/notification_service.dart';
import '../services/pedometer_service.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _goalLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'bajar_peso':
        return 'Bajar de peso';
      case 'ganar_musculo':
        return 'Ganar masa muscular';
      default:
        return 'Mantenerme activo';
    }
  }

  Future<void> _showRenewDialog(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final gym = context.read<GymProvider>();

    final plans = [
      {'name': 'Plan Básico Mensual', 'desc': 'Acceso ilimitado a zona de pesas y cardio', 'price': 65000.0},
      {'name': 'Plan Pro Full Clases', 'desc': 'Gimnasio + todas las clases grupales + FitBot', 'price': 95000.0},
      {'name': 'Plan VIP + Entrenador', 'desc': 'Acceso total + seguimiento personalizado 1 a 1', 'price': 150000.0},
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Elige tu plan FitZone',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Activación inmediata en tu cuenta',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ...plans.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: AppTheme.neonBorder,
                  boxShadow: AppTheme.neonBoxShadow,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryCrimson, size: 20),
                  ),
                  title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(p['desc'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,###').format(p['price'])} / mes',
                        style: const TextStyle(color: AppTheme.primaryCrimson, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final err = await gym.registrarPagoSimulado(
                        user: user,
                        membresia: p['name'] as String,
                        monto: p['price'] as double,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err ?? 'Plan activado correctamente.')),
                        );
                      }
                    },
                    child: const Text('Activar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gym = context.watch<GymProvider>();
    final pedo = context.watch<PedometerService>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();
    final pago = gym.ultimoPago;
    final activePlan = pago != null && pago.estaActiva;
    final daysLeft = pago != null ? pago.diasRestantes.clamp(0, 30) : 0;
    final daysRatio = (daysLeft / 30.0).clamp(0.0, 1.0);

    return RefreshIndicator(
      color: AppTheme.primaryCrimson,
      onRefresh: () async {
        await auth.refreshProfile();
        await gym.loadInitialData(user);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          // Encabezado con energía y jerarquía
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 18, height: 2.5, color: AppTheme.primaryCrimson),
                        const SizedBox(width: 8),
                        Text(
                          _greeting().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.nombre,
                      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: AppTheme.neonBorder,
                  boxShadow: AppTheme.neonBoxShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, size: 14, color: AppTheme.primaryCrimson),
                    const SizedBox(width: 5),
                    Text(
                      _goalLabel(user.objetivo),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tarjeta VIP Black-Card de Membresía con textura sutil de gimnasio y borde rojo neón
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
                    opacity: 0.22,
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
                          const Color(0xFF1F1115).withValues(alpha: 0.88),
                          const Color(0xFF111115).withValues(alpha: 0.94),
                        ],
                      ),
                    ),
                  ),
                ),
                // Acento rojo superior limpio
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
                              Icon(Icons.verified_rounded, color: AppTheme.primaryCrimson, size: 17),
                              SizedBox(width: 6),
                              Text(
                                'PASE FITZONE CLUB',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: activePlan ? AppTheme.primaryCrimson : AppTheme.cardElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activePlan ? 'ACTIVA' : 'INACTIVA',
                              style: TextStyle(
                                color: activePlan ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        pago?.membresia ?? 'Activa tu membresía hoy',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pago != null
                            ? 'Vence el ${DateFormat('dd MMM yyyy').format(pago.fechaVencimiento)} · $daysLeft días restantes'
                            : 'Desbloquea clases grupales, seguimiento de progreso y FitBot 24/7.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      if (activePlan) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: daysRatio,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            color: AppTheme.primaryCrimson,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRenewDialog(context),
                              icon: const Icon(Icons.bolt_rounded, size: 18),
                              label: Text(pago != null ? 'Renovar plan' : 'Activar plan'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () async {
                              await NotificationService().showInstantNotification(
                                id: 1001,
                                title: 'Recordatorio FitZone',
                                body: pago != null
                                    ? 'Tu ${pago.membresia} vence el ${DateFormat('dd/MM/yyyy').format(pago.fechaVencimiento)}.'
                                    : 'Recuerda activar tu plan FitZone para reservar tus clases.',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Recordatorio de membresía enviado.')),
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

          // Tarjetas de rendimiento del día con acentos vivos
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onNavigateTab(2),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMuted,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.directions_run_rounded, color: AppTheme.primaryCrimson, size: 18),
                              ),
                              Text(
                                '${(pedo.progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: AppTheme.primaryCrimson,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${pedo.stepsToday}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pasos · ${pedo.caloriesKcal.toStringAsFixed(0)} kcal',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pedo.progress,
                              minHeight: 5,
                              backgroundColor: AppTheme.borderSubtle,
                              color: AppTheme.primaryCrimson,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onNavigateTab(1),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMuted,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.event_available_rounded, color: AppTheme.primaryCrimson, size: 18),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${gym.misClases.length}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          const Text('Clases reservadas', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(
                            '${gym.todasClases.length} activas hoy',
                            style: const TextStyle(
                              color: AppTheme.primaryCrimson,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Accesos rápidos con íconos en rojo FitZone
          Row(
            children: [
              Expanded(
                child: _quickActionTile(
                  icon: Icons.chat_bubble_rounded,
                  title: 'FitBot',
                  subtitle: 'Tu asistente 24/7',
                  onTap: () => onNavigateTab(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionTile(
                  icon: Icons.insights_rounded,
                  title: 'Coach IA',
                  subtitle: 'Evalúa tu constancia',
                  onTap: () => onNavigateTab(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // Novedades y Promos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.primaryCrimson, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text(
                    'Novedades del club',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (gym.loadingHome)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCrimson),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (gym.anuncios.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryCrimson, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No hay promociones activas por ahora. Desliza hacia abajo para actualizar.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...gym.anuncios.map((a) {
              final imgUrl = (a.imagenUrl != null && a.imagenUrl!.isNotEmpty)
                  ? (a.imagenUrl!.startsWith('http') ? a.imagenUrl! : '${ApiConfig.baseUrl}${a.imagenUrl}')
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imgUrl != null)
                        Image.network(
                          imgUrl,
                          height: 145,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PROMO',
                                    style: TextStyle(
                                      color: AppTheme.primaryCrimson,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                if (a.fechaFin.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hasta ${a.fechaFin}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a.titulo,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.descripcion,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: AppTheme.neonBorder,
          boxShadow: AppTheme.neonBoxShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryCrimson, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
