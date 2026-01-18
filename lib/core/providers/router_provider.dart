import 'package:coisa_rapida/features/auth/providers/auth_provider.dart';
import 'package:coisa_rapida/features/auth/screens/cadastro_screen.dart';
import 'package:coisa_rapida/features/auth/screens/login_screen.dart';
import 'package:coisa_rapida/features/auth/screens/recuperar_senha_screen.dart';
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
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.cadastro,
        name: 'cadastro',
        builder: (context, state) => const CadastroScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperarSenha,
        name: 'recuperar-senha',
        builder: (context, state) => const RecuperarSenhaScreen(),
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
    final isCadastro = state.matchedLocation == AppRoutes.cadastro;
    final isRecuperarSenha = state.matchedLocation == AppRoutes.recuperarSenha;
    final isLoading = authState.isLoading;

    final isPublicPage = isLogin || isCadastro || isRecuperarSenha;

    // Se está carregando, só mantenha na splash, caso contrário deixe onde está
    if (isLoading) {
      return null;
    }

    // Não logado em página pública: deixa onde está
    if (!estaLogado && isPublicPage) {
      return null;
    }

    // Não logado em página privada: redireciona para login
    if (!estaLogado && !isPublicPage) {
      return AppRoutes.login;
    }

    // Logado em página pública ou splash: redireciona para home
    if (estaLogado && (isPublicPage || isSplash)) {
      return AppRoutes.home;
    }

    // Logado em página privada: deixa onde está
    return null;
  }
}
