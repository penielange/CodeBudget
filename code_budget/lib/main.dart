import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'data/app_repository.dart';
import 'data/models/models.dart';
import 'features/about_screen.dart';
import 'features/add_transaction_screen.dart';
import 'features/annual_stats_screen.dart';
import 'features/auth/landing_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/profile_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/categories_screen.dart';
import 'features/forecasts_screen.dart';
import 'features/help_screen.dart';
import 'features/history_screen.dart';
import 'features/home_screen.dart';
import 'features/settings_screen.dart';
import 'features/shell.dart';
import 'providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  final repo = AppRepository();
  await repo.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(ProviderScope(
    overrides: [repoProvider.overrideWithValue(repo)],
    child: CodeBudgetApp(repo: repo),
  ));
}

class CodeBudgetApp extends StatelessWidget {
  final AppRepository repo;
  const CodeBudgetApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: repo.isLoggedIn ? '/' : '/welcome',
      redirect: (context, state) {
        final loggedIn = repo.isLoggedIn;
        final loc = state.matchedLocation;
        final isAuth = loc == '/welcome' || loc == '/login' || loc == '/register';
        if (!loggedIn && !isAuth) return '/welcome';
        if (loggedIn && isAuth) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/welcome', builder: (_, __) => const LandingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/forecasts', builder: (_, __) => const ForecastsScreen()),
            GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
            GoRoute(path: '/annual', builder: (_, __) => const AnnualStatsScreen()),
          ],
        ),
        GoRoute(
          path: '/add',
          builder: (_, state) => AddTransactionScreen(
            existing: state.extra is TransactionModel ? state.extra as TransactionModel : null,
          ),
        ),
        GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
        GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
        GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'CodeBudget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
