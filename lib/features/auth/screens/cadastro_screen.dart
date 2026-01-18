import 'package:coisa_rapida/features/auth/providers/auth_provider.dart';
import 'package:coisa_rapida/shared/utils/ui_utils.dart';
import 'package:coisa_rapida/shared/widgets/campo_texto_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:validatorless/validatorless.dart';

class CadastroScreen extends ConsumerWidget {
  const CadastroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: CadastroForm(),
        ),
      ),
    );
  }
}

class CadastroForm extends ConsumerStatefulWidget {
  const CadastroForm({super.key});

  @override
  ConsumerState<CadastroForm> createState() => _CadastroFormState();
}

class _CadastroFormState extends ConsumerState<CadastroForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _senhaVisivel = false;

  bool get _camposPreenchidos {
    return _nomeController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _cpfController.text.trim().isNotEmpty &&
        _senhaController.text.trim().isNotEmpty &&
        _confirmarSenhaController.text.trim().isNotEmpty;
  }

  Future<void> handleCadastro() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_senhaController.text.trim() != _confirmarSenhaController.text.trim()) {
      UiUtils.mostrarErro(context, 'As senhas não coincidem');
      return;
    }

    final auth = ref.read(authProvider.notifier);
    auth.cadastrar(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      cpf: _cpfController.text.trim().replaceAll(RegExp(r'[^\d]'), ''),
      senha: _senhaController.text.trim(),
    );
  }

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(_atualizarEstadoBotao);
    _emailController.addListener(_atualizarEstadoBotao);
    _cpfController.addListener(_atualizarEstadoBotao);
    _senhaController.addListener(_atualizarEstadoBotao);
    _confirmarSenhaController.addListener(_atualizarEstadoBotao);
  }

  void _atualizarEstadoBotao() {
    setState(() {});
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous is AsyncLoading) {
            UiUtils.mostrarSucesso(context, 'Cadastro realizado com sucesso!');
          }
        },
        error: (error, stackTrace) {
          if (previous is AsyncLoading) {
            UiUtils.mostrarErro(context, error.toString());
          }
        },
      );
    });

    final isLoading = ref.watch(authProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preencha os dados para iniciar.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),

          const SizedBox(height: 16),

          CampoTexto(
            controller: _nomeController,
            label: 'Nome Completo',
            placeholder: 'Digite seu nome',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            readOnly: isLoading,
            validator: Validatorless.multiple([
              Validatorless.required('Nome é obrigatório'),
              Validatorless.min(2, 'Deve conter ao menos 2 letras'),
            ]),
          ),

          const SizedBox(height: 16),

          CampoTexto(
            controller: _emailController,
            label: 'Email',
            placeholder: 'Digite seu email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: isLoading,
            validator: Validatorless.multiple([
              Validatorless.email('Insira um email válido'),
              Validatorless.min(2, 'Deve conter ao menos 2 letras'),
            ]),
          ),

          const SizedBox(height: 16),

          CampoTexto(
            controller: _cpfController,
            label: 'CPF',
            placeholder: 'Digite seu CPF',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            readOnly: isLoading,
            validator: Validatorless.multiple([
              Validatorless.required('CPF é obrigatório'),
              Validatorless.cpf('CPF inválido'),
            ]),
          ),

          const SizedBox(height: 16),

          CampoTexto(
            controller: _senhaController,
            label: 'Senha',
            placeholder: 'Digite sua senha',
            prefixIcon: Icons.lock_outline,
            obscureText: !_senhaVisivel,
            keyboardType: TextInputType.visiblePassword,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
              icon: Icon(
                _senhaVisivel ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            readOnly: isLoading,
            validator: Validatorless.multiple([
              Validatorless.required('Senha é obrigatória'),
              Validatorless.min(8, 'Senha deve ter no mínimo 8 caracteres'),
              Validatorless.max(128, 'Senha deve ter no máximo 128 caracteres'),
              (value) {
                if (value == null || value.isEmpty) return null;
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'Senha deve conter pelo menos uma letra minúscula';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Senha deve conter pelo menos uma letra maiúscula';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Senha deve conter pelo menos um número';
                }
                if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                  return 'Senha deve conter pelo menos um caractere especial';
                }
                return null;
              },
            ]),
          ),

          const SizedBox(height: 16),

          CampoTexto(
            controller: _confirmarSenhaController,
            label: 'Confirmar Senha',
            placeholder: 'Confirme sua senha',
            prefixIcon: Icons.lock_outline,
            obscureText: !_senhaVisivel,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
              icon: Icon(
                _senhaVisivel ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            readOnly: isLoading,
            validator: Validatorless.multiple([
              Validatorless.required('Confirmar Senha é obrigatória'),
              Validatorless.min(8, 'Senha deve ter no mínimo 8 caracteres'),
              Validatorless.max(128, 'Senha deve ter no máximo 128 caracteres'),
              (value) {
                if (value == null || value.isEmpty) return null;
                if (value != _senhaController.text.trim()) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ]),
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: (isLoading || !_camposPreenchidos)
                ? null
                : handleCadastro,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Cadastrar'),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ja tem uma conta?'),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Fazer Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
