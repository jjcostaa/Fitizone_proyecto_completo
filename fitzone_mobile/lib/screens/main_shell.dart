import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import '../services/notification_service.dart';
import '../services/pedometer_service.dart';
import '../widgets/offline_banner.dart';
import 'home_screen.dart';
import 'classes_screen.dart';
import 'activity_screen.dart';
import 'fitbot_screen.dart';
import 'ai_analytics_screen.dart';
import 'admin_screens.dart';
import 'trainer_screens.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    final gym = context.read<GymProvider>();
    final pedo = context.read<PedometerService>();
    final user = auth.user;

    if (user != null) {
      gym.resetSessionState();
      if (user.isAdmin) {
        pedo.resetSession();
        await gym.loadAdminDashboard();
      } else if (user.isEntrenador) {
        pedo.resetSession();
        await gym.loadTrainerDashboard(user);
      } else {
        await gym.loadInitialData(user);
        auth.refreshProfile();
        await pedo.initForUser(user.id);
        pedo.onGoalReached = () {
          NotificationService().showInstantNotification(
            id: 9001,
            title: 'Meta diaria alcanzada',
            body: 'Completaste tus ${pedo.dailyGoal} pasos hoy en FitZone.',
          );
        };
        pedo.startTracking();
      }
    }
  }

  Future<void> _retrySync() async {
    final auth = context.read<AuthProvider>();
    await auth.checkConnectionNow();
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gym = context.watch<GymProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final isOffline = !auth.hasDeviceNetwork || gym.usingOfflineData;

    late final List<Widget> screens;
    late final List<String> titles;
    late final List<IconData> headerIcons;
    late final List<NavigationDestination> destinations;
    late final String roleLabel;

    if (user.isAdmin) {
      roleLabel = 'ADMIN';
      screens = [
        AdminDashboardTab(onNavigateTab: (i) => setState(() => _selectedIndex = i)),
        const AdminUsersTab(),
        const AdminPredictionsTab(),
        const AdminOptimizationTab(),
      ];
      titles = ['FITZONE', 'Usuarios', 'Riesgos IA', 'Horarios'];
      headerIcons = const [
        Icons.dashboard_rounded,
        Icons.people_rounded,
        Icons.analytics_rounded,
        Icons.tune_rounded,
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Panel',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Usuarios',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: 'Riesgos',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: 'Horarios',
        ),
      ];
    } else if (user.isEntrenador) {
      roleLabel = 'COACH';
      screens = [
        TrainerDashboardTab(onNavigateTab: (i) => setState(() => _selectedIndex = i)),
        const TrainerClassesTab(),
        const TrainerStudentsTab(),
        const FitbotScreen(),
      ];
      titles = ['FITZONE', 'Mis Clases', 'Alumnos', 'FitBot'];
      headerIcons = const [
        Icons.space_dashboard_rounded,
        Icons.fitness_center_rounded,
        Icons.groups_rounded,
        Icons.chat_bubble_rounded,
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center_rounded),
          label: 'Clases',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Alumnos',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'FitBot',
        ),
      ];
    } else {
      roleLabel = '';
      screens = [
        HomeScreen(onNavigateTab: (i) => setState(() => _selectedIndex = i)),
        const ClassesScreen(),
        const ActivityScreen(),
        const FitbotScreen(),
        const AiAnalyticsScreen(),
      ];
      titles = ['FITZONE', 'Clases', 'Actividad', 'FitBot', 'Coach IA'];
      headerIcons = const [
        Icons.home_rounded,
        Icons.fitness_center_rounded,
        Icons.directions_run_rounded,
        Icons.chat_bubble_rounded,
        Icons.insights_rounded,
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center_rounded),
          label: 'Clases',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_run_outlined),
          selectedIcon: Icon(Icons.directions_run_rounded),
          label: 'Actividad',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'FitBot',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Coach IA',
        ),
      ];
    }

    final safeIndex = _selectedIndex.clamp(0, screens.length - 1);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderSubtle),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryCrimson,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  headerIcons[safeIndex],
                  key: ValueKey(headerIcons[safeIndex]),
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titles[safeIndex],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: safeIndex == 0 ? 2.2 : 0.2,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    roleLabel.isNotEmpty ? 'FITNESS CLUB · $roleLabel' : 'FITNESS CLUB',
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                      color: roleLabel.isNotEmpty ? AppTheme.primaryCrimson : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: AppTheme.neonBorder,
                  boxShadow: AppTheme.neonBoxShadow,
                ),
                alignment: Alignment.center,
                child: Text(
                  (user.nombre.isNotEmpty ? user.nombre[0] : 'F').toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(
            isOffline: isOffline,
            lastSync: gym.lastSync,
            onRetry: _retrySync,
          ),
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: destinations,
        ),
      ),
    );
  }
}
