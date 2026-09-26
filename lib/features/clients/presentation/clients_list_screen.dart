import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/data/client_repository.dart';
import 'package:lynx_app/features/clients/data/models/client.dart';
import 'package:lynx_app/features/clients/presentation/add_client_screen.dart';
import 'package:lynx_app/features/clients/presentation/client_detail_screen.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// Staff view of the tenant's clients.
class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final _scroll = ScrollController();

  /// Local copy for optimistic drag-reorder; kept in sync with the provider.
  List<Client>? _clients;

  String get _tenantId =>
      ref.read(currentUserProvider).valueOrNull?.tenantId ?? '';

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
    if (created == true) ref.invalidate(clientsProvider);
  }

  Future<void> _open(Client c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(personId: c.id)),
    );
    ref.invalidate(clientsProvider);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final list = [...?_clients];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() => _clients = list);
    try {
      await ClientRepository.setClientOrder(
        tenantId: _tenantId,
        orderedIds: list.map((c) => c.id).toList(),
      );
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Keep the local (optimistically-reorderable) copy in sync with the provider.
    ref.listen(clientsProvider, (prev, next) {
      next.whenData((c) {
        if (mounted) setState(() => _clients = c);
      });
    });
    final clientsAsync = ref.watch(clientsProvider);
    final clients = _clients;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_clients',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.newClient),
      ),
      body: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(title: l.clientsTitle, controller: _scroll),
          if (clients == null && clientsAsync.isLoading)
            const SliverSkeletonCards()
          else if (clients == null && clientsAsync.hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Text(l.somethingWentWrong,
                      style: AppTextStyles.bodySmall)),
            )
          else if (clients == null || clients.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(l.clientsEmpty,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
              sliver: SliverReorderableList(
                itemCount: clients.length,
                onReorderItem: _reorder,
                itemBuilder: (_, i) => ReorderableDelayedDragStartListener(
                  key: ValueKey(clients[i].id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ClientCard(
                      client: clients[i],
                      onTap: () => _open(clients[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
          backgroundColor: AppColors.primary,
          child: Text(client.initials,
              style: AppTextStyles.button.copyWith(color: AppColors.onPrimary)),
        ),
        title: Text(client.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(client.hasAccount ? l.accountLinked : l.accountNone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ),
    );
  }
}
