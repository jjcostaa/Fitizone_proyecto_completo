import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/gym_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/offline_cache_service.dart';
import 'services/pedometer_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  await NotificationService().init();

  final apiService = ApiService();
  final cacheService = OfflineCacheService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api: apiService, cache: cacheService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => GymProvider(api: apiService, cache: cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => PedometerService(),
        ),
      ],
      child: const FitZoneApp(),
    ),
  );
}

class FitZoneApp extends StatelessWidget {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const FitZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitZone Fitness Club',
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            if (constraints.maxWidth > 520 && child != null) {
              return Container(
                color: const Color(0xFF070708),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Container(
                  width: 404,
                  height: constraints.maxHeight.clamp(680.0, 860.0),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFF232329), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        height: 20,
                        color: AppTheme.bgDark,
                        alignment: Alignment.center,
                        child: Container(
                          width: 84,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF24242A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryCrimson,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'FITZONE',
                style: TextStyle(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'FITNESS CLUB',
                style: TextStyle(
                  letterSpacing: 2.6,
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: AppTheme.primaryCrimson, strokeWidth: 2.2),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: auth.isAuthenticated
          ? const MainShell(key: ValueKey('main_shell'))
          : const LoginScreen(key: ValueKey('login_screen')),
    );
  }
}
