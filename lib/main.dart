import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'core/constants.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/quiz_page.dart';
import 'presentation/pages/result_page.dart';
import 'domain/providers.dart'; // Import for QuizMode

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: This will fail until valid URL/Key are provided in constants.dart
  // Wrapping in try-catch to allow app to run (with error) if config is missing logic
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    print('Supabase init failed (Update Constants): $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Check if user is logged in
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final loggingIn = state.uri.path == '/auth';

    if (!loggedIn && !loggingIn) return '/auth';
    if (loggedIn && loggingIn) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?; // Safe cast
        if (extra == null) return const SizedBox(); // Fallback
        
        return QuizPage(
          mode: extra['mode'] as QuizMode? ?? QuizMode.exam, // Safe access
          target: extra['target'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?; 
        if (extra == null) return const SizedBox();

        return ResultPage(
          correctCount: extra['correctCount'] as int? ?? 0,
          totalCount: extra['totalCount'] as int? ?? 0,
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IP Skills Level 2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
