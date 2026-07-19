import 'package:flutter/material.dart';

import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                '¿Formas parte de un equipo o quieres crear el tuyo?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Crea el grupo de tu bloque quirúrgico, servicio o equipo y documenta cómo trabajáis: '
                'catálogo de instrumental, técnicas, protocolos y tarjetas de preferencia compartidas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: const Text('Crear cuenta'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: const Text('Ya tengo cuenta — iniciar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
