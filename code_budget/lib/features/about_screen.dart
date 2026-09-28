import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../shared/money_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: MoneyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 100, errorBuilder: (_, __, ___) {
                  return const Icon(Icons.account_balance_wallet, size: 80, color: AppColors.primary);
                }),
                const SizedBox(height: 24),
                Text('CodeBudget', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Gestion budgétaire personnelle\nbasée sur vos revenus',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Column(
                    children: [
                      Text('Created by', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      SizedBox(height: 4),
                      Text(
                        'CodeAnytime',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text("L'effusion numérique", style: TextStyle(fontSize: 13, color: AppColors.primaryLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
