import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) return const SizedBox();
        
        // answerResultsをMap<int, Map<String, dynamic>>に変換
        Map<int, Map<String, dynamic>>? answerResults;
        final rawResults = extra['answerResults'];
        if (rawResults != null && rawResults is Map) {
          answerResults = {};
          rawResults.forEach((key, value) {
            final intKey = key is int ? key : int.tryParse(key.toString());
            if (intKey != null && value is Map) {
              answerResults![intKey] = Map<String, dynamic>.from(value);
            }
          });
        }
        
        return QuizPage(
          mode: extra['mode'] as QuizMode? ?? QuizMode.exam,
          target: extra['target'] as String? ?? '',
          resume: extra['resume'] as bool? ?? false,
          startIndex: extra['currentIndex'] as int?,
          correctCount: extra['correctCount'] as int?,
          answeredCount: extra['answeredCount'] as int?,
          answerResults: answerResults,
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
          skippedCount: extra['skippedCount'] as int? ?? 0,
        );
      },
    ),

  ],
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and refresh router
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _router.refresh();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IP Skills Level 3',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
      ],
      locale: const Locale('ja'),
    );
  }
}
