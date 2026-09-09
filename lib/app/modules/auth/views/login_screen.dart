import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../vamos_app.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
            child: TweenAnimationBuilder<double>(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: const Cubic(0.16, 1, 0.3, 1),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: child,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'vamos-logo.png',
                        width: 190,
                        semanticLabel: 'Vamos Arena Fit',
                      ),
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Selamat datang',
                      style: TextStyle(
                        color: ink,
                        fontSize: AppText.hero,
                        fontFamily: AppText.displayFamily,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Masuk dengan akun staff VAMOS OPS untuk memulai aktivitas.',
                      style: TextStyle(
                        color: muted,
                        fontSize: AppText.md,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'EMAIL',
                                style: TextStyle(
                                  fontSize: AppText.sm,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                key: const Key('login-email'),
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  hintText: 'nama@vamos.fit',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                onFieldSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Email wajib diisi.';
                                  }
                                  if (!GetUtils.isEmail(email)) {
                                    return 'Format email belum valid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 17),
                              const Text(
                                'KATA SANDI',
                                style: TextStyle(
                                  fontSize: AppText.sm,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => TextFormField(
                                  key: const Key('login-password'),
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: controller.obscurePassword.value,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan kata sandi',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: controller.obscurePassword.value
                                          ? 'Tampilkan kata sandi'
                                          : 'Sembunyikan kata sandi',
                                      onPressed: () =>
                                          controller.obscurePassword.toggle(),
                                      icon: Icon(
                                        controller.obscurePassword.value
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _submit(controller),
                                  validator: (value) => (value?.length ?? 0) < 8
                                      ? 'Kata sandi minimal 8 karakter.'
                                      : null,
                                ),
                              ),
                              Obx(
                                () => AnimatedSize(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  curve: const Cubic(0.16, 1, 0.3, 1),
                                  child: controller.errorMessage.value == null
                                      ? const SizedBox(height: 20)
                                      : Container(
                                          key: const Key('login-error'),
                                          margin: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: danger.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: danger.withValues(
                                                alpha: 0.22,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                color: danger,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 9),
                                              Expanded(
                                                child: Text(
                                                  controller
                                                      .errorMessage
                                                      .value!,
                                                  style: const TextStyle(
                                                    color: danger,
                                                    fontSize: AppText.base,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              Obx(
                                () => FilledButton(
                                  key: const Key('login-submit'),
                                  onPressed: controller.isAuthenticating.value
                                      ? null
                                      : () => _submit(controller),
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    child: controller.isAuthenticating.value
                                        ? const SizedBox(
                                            key: Key('login-progress'),
                                            width: 21,
                                            height: 21,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: ink,
                                            ),
                                          )
                                        : const Text(
                                            'MASUK KE VAMOS OPS',
                                            key: Key('login-label'),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: muted),
                        SizedBox(width: 7),
                        // Flexible so the line wraps under large text
                        // settings instead of overflowing the row.
                        Flexible(
                          child: Text(
                            'Sesi terenkripsi · VAMOS Arena Fit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: AppText.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthController controller) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await controller.login(_emailController.text, _passwordController.text);
  }
}
