import 'package:coisa_rapida/features/auth/providers/auth_provider.dart';
import 'package:coisa_rapida/shared/utils/ui_utils.dart';
import 'package:coisa_rapida/shared/widgets/campo_texto_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:validatorless/validatorless.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: LoginForm(),
        ),
      ),
    );
  }
}

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_atualizarEstadoBotao);
    _senhaController.addListener(_atualizarEstadoBotao);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _atualizarEstadoBotao() {
    setState(() {});
  }

  bool get _camposPreenchidos {
    return _emailController.text.trim().isNotEmpty &&
        _senhaController.text.trim().isNotEmpty;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _senhaController.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String?>>(authProvider, (previous, next) {
      if (next.hasError) {
        UiUtils.mostrarErro(context, next.error.toString());
      }
    });

    final isLoading = ref.watch(authProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          Image.asset('assets/images/coisa_rapida_logo.png', height: 100),

          const SizedBox(height: 8),

          Text(
            'Faça login para continuar',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withAlpha(190),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          CampoTexto(
            controller: _emailController,
            label: 'Email',
            placeholder: 'Digite seu email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: isLoading,
            validator: Validatorless.multiple([
              Validatorless.required('Email é obrigatório'),
              Validatorless.email('Email inválido'),
            ]),
          ),

          const SizedBox(height: 16),

          CampoTexto(
            controller: _senhaController,
            label: 'Senha',
            placeholder: 'Digite sua senha',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: isLoading
                  ? null
                  : () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
            obscureText: !_senhaVisivel,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            readOnly: isLoading,
            validator: Validatorless.required('Senha é obrigatória'),
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: (isLoading || !_camposPreenchidos) ? null : _handleLogin,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Entrar'),
            ),
          ),

          const SizedBox(height: 16),

          // Link para recuperação de senha (opcional)
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    // Navegar para recuperação de senha
                    // context.push('/recuperar-senha');
                  },
            child: const Text('Esqueceu sua senha?'),
          ),
        ],
      ),
    );
  }
}
