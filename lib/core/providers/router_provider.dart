import 'package:coisa_rapida/features/auth/providers/auth_provider.dart';
import 'package:coisa_rapida/features/auth/screens/login_screen.dart';
import 'package:coisa_rapida/features/auth/screens/splash_screen.dart';
import 'package:coisa_rapida/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_routes_constants.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);

    final estaLogado = authState.value != null;
    final isLogin = state.matchedLocation == AppRoutes.login;
    final isSplash = state.matchedLocation == AppRoutes.splash;
    final isLoading = authState.isLoading;

    if (isLoading) {
      if (!isSplash) {
        return null;
      }
      return null;
    }

    if (!estaLogado) {
      return AppRoutes.login;
    }

    if (isLogin) {
      return AppRoutes.home;
    }

    if (isSplash) {
      return AppRoutes.home;
    }

    return null;
  }
}
