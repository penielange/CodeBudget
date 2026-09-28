import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../shared/money_background.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide CodeBudget')),
      body: MoneyBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.flag_rounded,
              title: 'Objectif de l’application',
              body:
                  'CodeBudget vous aide à maîtriser vos finances personnelles. '
                  'Tout part de vos revenus : vous définissez un budget mensuel '
                  'qui ne peut pas dépasser ce que vous gagnez, vous enregistrez '
                  'vos dépenses, et l’app vous alerte avant les dérapages.',
            ),
            _Section(
              icon: Icons.payments_rounded,
              title: '1. Enregistrez vos revenus',
              body:
                  'Commencez toujours par ajouter un revenu (salaire, prime, etc.) '
                  'via le bouton « + Transaction ». Le solde se calcule ainsi :\n'
                  'Solde = Total des revenus − Total des dépenses.',
            ),
            _Section(
              icon: Icons.pie_chart_rounded,
              title: '2. Définissez votre budget (Prévisions)',
              body:
                  'Dans l’onglet Prévisions, choisissez un mois et saisissez un budget. '
                  'Le budget part de 0 : c’est vous qui le fixez. '
                  'Il ne peut pas être supérieur aux revenus du mois. '
                  'Répartissez-le par catégories de dépenses si vous le souhaitez.',
            ),
            _Section(
              icon: Icons.shopping_cart_rounded,
              title: '3. Enregistrez vos dépenses',
              body:
                  'Ajoutez chaque dépense avec sa catégorie. '
                  'Sans « mode découvert », une dépense supérieure au solde est refusée.',
            ),
            _Section(
              icon: Icons.notifications_active_rounded,
              title: '4. Alertes (en rouge)',
              body:
                  'Lorsque les dépenses atteignent 75 % du budget (global ou par catégorie), '
                  'une alerte rouge s’affiche sur l’accueil pour vous prévenir à temps.',
            ),
            _Section(
              icon: Icons.history_rounded,
              title: '5. Historique mensuel',
              body:
                  'L’onglet Historique montre les transactions mois par mois. '
                  'Faites glisser une ligne vers la gauche pour la supprimer.',
            ),
            _Section(
              icon: Icons.category_rounded,
              title: '6. Catégories personnalisées',
              body:
                  'Dans Réglages → Catégories, créez, modifiez ou supprimez '
                  'vos types de dépenses et sources de revenus.',
            ),
            _Section(
              icon: Icons.bar_chart_rounded,
              title: '7. Statistiques annuelles',
              body:
                  'L’icône graphique (accueil) affiche les courbes revenus/dépenses '
                  'sur 12 mois, le solde annuel et la répartition par catégorie.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Created by CodeAnytime', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text("L'effusion numérique", style: TextStyle(color: AppColors.primaryLight)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 64,
          errorBuilder: (_, __, ___) => const Icon(Icons.help_outline, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text('Comment ça marche ?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Un guide rapide pour bien utiliser CodeBudget',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(height: 1.45, color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
