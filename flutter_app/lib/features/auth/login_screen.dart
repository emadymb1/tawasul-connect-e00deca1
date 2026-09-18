import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale_controller.dart';
import '../../l10n/strings.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(strings: strings),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.signIn,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: TawasulColors.forest,
                              ),
                            ),
                          ),
                          const _LanguageButton(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.signInHint,
                        style: const TextStyle(
                            color: TawasulColors.muted, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      Text(strings.usernameLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? strings.requiredField
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(strings.passwordLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? strings.requiredField
                            : null,
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: TawasulColors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            auth.error == 'network' ||
                                    auth.error == 'missing_token'
                                ? strings.signInFailed
                                : auth.error!,
                            style: const TextStyle(
                                color: TawasulColors.red,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.busy ? null : _submit,
                        child: Text(
                            auth.busy ? strings.signingIn : strings.signIn),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.strings});
  final S strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TawasulColors.forest,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: TawasulColors.cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text('ت',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: TawasulColors.forest)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.appName,
                          style: const TextStyle(
                              color: TawasulColors.cream,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      Text(strings.appTagline.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0x99F6F1E7),
                              fontSize: 11,
                              letterSpacing: 2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                strings.isArabic
                    ? 'مساحة عمل واحدة للمدرسة بالكامل.'
                    : 'One calm workspace for the whole school.',
                style: const TextStyle(
                  color: TawasulColors.cream,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.isArabic
                    ? 'الجداول والحضور والدرجات والإعلانات — بحسابك في تواصل.'
                    : 'Timetables, attendance, grades and notices — with the Tawasul account your school gave you.',
                style: const TextStyle(
                    color: Color(0xCCF6F1E7), fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return IconButton(
      tooltip: S.of(context).language,
      onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x221E3D2B)),
        ),
        alignment: Alignment.center,
        child: Text(
          locale.languageCode == 'ar' ? 'EN' : 'ع',
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: TawasulColors.forest),
        ),
      ),
    );
  }
}
