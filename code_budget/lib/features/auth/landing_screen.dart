import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1B4D), Color(0xFF1D4ED8), Color(0xFF059669)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 140,
                    width: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 100, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'CodeBudget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Planifiez  ·  Suivez  ·  Économisez',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Text(
                  'Maîtrisez votre budget personnel.\nBasé sur vos revenus, simple et offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), height: 1.45),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.push('/register'),
                    child: const Text('Créer un compte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.push('/login'),
                    child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Created by CodeAnytime',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  "L'effusion numérique",
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
