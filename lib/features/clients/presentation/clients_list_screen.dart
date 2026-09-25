import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/clients/data/models/client.dart';
import 'package:lynx_app/features/clients/presentation/add_client_screen.dart';
import 'package:lynx_app/features/clients/presentation/client_detail_screen.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';

/// Staff view of the tenant's clients.
class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
    if (created == true) ref.invalidate(clientsProvider);
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Client c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(personId: c.id)),
    );
    ref.invalidate(clientsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.clientsTitle, style: AppTextStyles.heading3)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.newClient),
      ),
      body: SafeArea(
        child: clientsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.forest)),
          error: (_, _) =>
              Center(child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
          data: (clients) => clients.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(l.clientsEmpty,
                        textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                  itemCount: clients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _ClientCard(
                    client: clients[i],
                    onTap: () => _open(context, ref, clients[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.onTap});
  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.forest,
          child: Text(client.initials,
              style: AppTextStyles.button.copyWith(color: AppColors.onPrimary)),
        ),
        title: Text(client.fullName,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(client.hasAccount ? l.accountLinked : l.accountNone,
            style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ),
    );
  }
}
