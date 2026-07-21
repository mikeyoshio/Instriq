import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 72),
              const SizedBox(height: 16),
              Text('Instriq', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Text(
                l10n.welcomeQuestion,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(l10n.welcomeBody, textAlign: TextAlign.center),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: Text(l10n.createAccount),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: Text(l10n.alreadyHaveAccount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
