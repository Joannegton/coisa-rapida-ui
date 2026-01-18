import 'package:coisa_rapida/shared/utils/ui_utils.dart';
import 'package:coisa_rapida/shared/widgets/campo_texto_widget.dart';
import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRecuperarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implementar lógica de recuperação de senha
      await Future.delayed(const Duration(seconds: 2)); // Simulação

      if (mounted) {
        UiUtils.mostrarSucesso(
          context,
          'Email de recuperação enviado! Verifique sua caixa de entrada.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UiUtils.mostrarErro(context, 'Erro ao enviar email de recuperação');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 24),

                Text(
                  'Esqueceu sua senha?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Digite seu email para receber instruções de recuperação',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withAlpha(190),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                CampoTexto(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'Digite seu email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isLoading,
                  validator: Validatorless.multiple([
                    Validatorless.required('Email é obrigatório'),
                    Validatorless.email('Email inválido'),
                  ]),
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed:
                      (_isLoading || _emailController.text.trim().isEmpty)
                      ? null
                      : _handleRecuperarSenha,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Enviar Email'),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Voltar ao Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
