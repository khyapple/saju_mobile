import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'providers/auth_provider.dart';
import 'providers/profiles_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/profiles/profiles_screen.dart';
import 'screens/profiles/profile_detail_screen.dart';
import 'screens/profiles/add_profile_screen.dart';
import 'screens/consultation/consultation_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/profiles/life_events_screen.dart';
import 'screens/compatibility/compatibility_screen.dart';
import 'screens/splash/splash_screen.dart';

class SajuApp extends StatefulWidget {
  const SajuApp({super.key});

  @override
  State<SajuApp> createState() => _SajuAppState();
}

class _SajuAppState extends State<SajuApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final loggedIn = _authProvider.isLoggedIn;
        final path = state.uri.path;
        if (path == '/splash') return null; // 스플래시는 항상 허용
        final publicPaths = ['/login', '/signup'];
        if (!loggedIn && !publicPaths.contains(path)) return '/login';
        if (loggedIn && publicPaths.contains(path)) return '/profiles';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/profiles', builder: (_, __) => const ProfilesScreen()),
        GoRoute(path: '/profiles/new', builder: (_, __) => const AddProfileScreen()),
        GoRoute(
          path: '/profiles/:id',
          builder: (_, state) =>
              ProfileDetailScreen(profileId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/profiles/:id/consultation',
          builder: (_, state) =>
              ConsultationScreen(profileId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/profiles/:id/events',
          builder: (_, state) =>
              LifeEventsScreen(profileId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/compatibility', builder: (_, __) => const CompatibilityScreen()),
        GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ProfilesProvider()),
      ],
      child: MaterialApp.router(
        title: '사주',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
        ],
        locale: const Locale('ko'),
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: kGold,
        onPrimary: kInk,
        surface: kCosmicDeep,
        onSurface: kDark,
        secondary: kSecondaryGold,
        error: kErrorColor,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: kCosmicDeep,
      textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).copyWith(
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 32, fontWeight: FontWeight.w300, color: kDark),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 40, fontWeight: FontWeight.w300, color: kDark),
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 52, fontWeight: FontWeight.w300, color: kDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: kDark),
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: kDark),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kLightPanel,
        contentTextStyle: const TextStyle(color: kDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
