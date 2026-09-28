import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../shared/money_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: MoneyBackground(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Color(0xFF2563EB)),
              title: const Text('Mon profil'),
              subtitle: const Text('Compte, mot de passe, devise'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile'),
            ),

            ListTile(
              title: const Text('Devise'),
              subtitle: Text(repo.currency),
              onTap: () async {
                final c = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Devise'),
                    children: ['FCFA', 'EUR', 'USD']
                        .map((e) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e), child: Text(e)))
                        .toList(),
                  ),
                );
                if (c != null) {
                  await repo.setCurrency(c);
                  setState(() {});
                }
              },
            ),
            SwitchListTile(
              title: const Text('Alertes à 75 % du budget'),
              value: repo.notif75,
              onChanged: (v) async {
                await repo.setNotif75(v);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Autoriser le découvert'),
              value: repo.allowOverdraft,
              onChanged: (v) async {
                await repo.setAllowOverdraft(v);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('Catégories & sources de revenus'),
              onTap: () => context.push('/categories'),
            ),
            ListTile(
              title: const Text('Statistiques annuelles'),
              subtitle: const Text('Revenus, dépenses et bilan de l\'année'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/annual'),
            ),
            ListTile(
              title: const Text('Guide / Aide'),
              subtitle: const Text('Comment utiliser CodeBudget'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/help'),
            ),
            ListTile(
              title: const Text('À propos'),
              subtitle: const Text('Created by CodeAnytime'),
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      ),
    );
  }
}
