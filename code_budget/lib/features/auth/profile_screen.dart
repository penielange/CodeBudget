import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_repository.dart';
import '../../providers.dart';
import '../../shared/money_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _phone;
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  String _currency = 'FCFA';

  @override
  void initState() {
    super.initState();
    final u = ref.read(repoProvider).currentUser;
    _name = TextEditingController(text: u?.displayName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _currency = u?.currency ?? 'FCFA';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _oldPass.dispose();
    _newPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final user = repo.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: MoneyBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  (user?.displayName.isNotEmpty == true ? user!.displayName[0] : '?').toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(user?.email ?? '', style: TextStyle(color: AppColors.textSecondary))),
            const SizedBox(height: 24),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom affiché')),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'Devise'),
              items: ['FCFA', 'EUR', 'USD', 'XOF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'FCFA'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await repo.updateProfile(displayName: _name.text, phone: _phone.text, currency: _currency);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.income),
                    );
                  }
                } on AuthException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.expense));
                  }
                }
              },
              child: const Text('Enregistrer le profil'),
            ),
            const SizedBox(height: 28),
            Text('Changer le mot de passe', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: _oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'Ancien mot de passe')),
            const SizedBox(height: 12),
            TextField(controller: _newPass, obscureText: true, decoration: const InputDecoration(labelText: 'Nouveau mot de passe')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                try {
                  await repo.changePassword(oldPassword: _oldPass.text, newPassword: _newPass.text);
                  _oldPass.clear();
                  _newPass.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mot de passe modifié'), backgroundColor: AppColors.income),
                    );
                  }
                } on AuthException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.expense));
                  }
                }
              },
              child: const Text('Mettre à jour le mot de passe'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () async {
                await repo.logout();
                if (mounted) context.go('/welcome');
              },
              child: const Text('Se déconnecter'),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('CodeBudget · CodeAnytime', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
