import 'package:flutter/material.dart';

import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';

class _OnboardingPage {
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;

  const _OnboardingPage({required this.icon, required this.title, required this.body});
}

const _pages = [
  _OnboardingPage(
    icon: Icons.local_hospital_outlined,
    title: _title1,
    body: _body1,
  ),
  _OnboardingPage(
    icon: Icons.style_outlined,
    title: _title2,
    body: _body2,
  ),
  _OnboardingPage(
    icon: Icons.groups_outlined,
    title: _title3,
    body: _body3,
  ),
];

String _title1(AppLocalizations l10n) => l10n.onboardingPage1Title;
String _body1(AppLocalizations l10n) => l10n.onboardingPage1Body;
String _title2(AppLocalizations l10n) => l10n.onboardingPage2Title;
String _body2(AppLocalizations l10n) => l10n.onboardingPage2Body;
String _title3(AppLocalizations l10n) => l10n.onboardingPage3Title;
String _body3(AppLocalizations l10n) => l10n.onboardingPage3Body;

/// Bienvenida de 3 pasos mostrada UNA SOLA VEZ, la primera vez que se abre la
/// app (ver el flag local `has_seen_onboarding` comprobado en main.dart, mismo
/// patrón que el aviso de "nueva versión disponible" -- SharedPreferences
/// inline, sin servicio dedicado). No pide cuenta ni conexión: solo explica
/// qué es Instriq y qué se puede hacer sin registrarse, antes de aterrizar en
/// el Inicio real.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _page == _pages.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(InstriqSpacing.sm),
                  child: Visibility(
                    visible: !isLast,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(l10n.onboardingSkip),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: InstriqSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              page.icon,
                              size: 56,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: InstriqSpacing.xl),
                          Text(
                            page.title(l10n),
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: InstriqSpacing.md),
                          Text(
                            page.body(l10n),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(InstriqSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: InstriqSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(isLast ? l10n.onboardingStart : l10n.onboardingNext),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
