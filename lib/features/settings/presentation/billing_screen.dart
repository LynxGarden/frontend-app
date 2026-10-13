import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/settings/data/models/invoice.dart';
import 'package:lynx_app/features/settings/providers/billing_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Settings → Billing: the user's (mock) invoice history.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppNavBar(title: l.billingTitle),
          Expanded(
            child: async.when(
              loading: () => const _BillingSkeleton(),
              error: (_, _) => _Empty(message: l.noInvoices),
              data: (invoices) {
                if (invoices.isEmpty) return _Empty(message: l.noInvoices);
                return _BillingList(invoices: invoices);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingList extends StatelessWidget {
  const _BillingList({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final totalPaid = invoices
        .where((i) => i.isPaid)
        .fold<int>(0, (sum, i) => sum + i.amountCents);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (totalPaid > 0) ...[
          _TotalHeader(totalPaid: totalPaid, currency: invoices.first.currency),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final invoice in invoices)
          _InvoiceCard(invoice: invoice, locale: locale),
      ],
    );
  }
}

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.totalPaid, required this.currency});

  final int totalPaid;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Σ',
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.textSecondary)),
          Text(
            '${(totalPaid / 100).toStringAsFixed(2)} $currency',
            style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.locale});

  final Invoice invoice;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final df = DateFormat.yMMMd(locale);
    final dateLabel = invoice.isPaid && invoice.paidAt != null
        ? l.paidOn(df.format(invoice.paidAt!))
        : df.format(invoice.issuedAt);

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.description,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(dateLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(invoice.formattedAmount,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              _StatusChip(paid: invoice.isPaid),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = paid ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        paid ? l.invoicePaid : l.invoicePending,
        style: AppTextStyles.bodySmall
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _BillingSkeleton extends StatelessWidget {
  const _BillingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 16),
                        SizedBox(height: AppSpacing.xs),
                        SkeletonBox(width: 90, height: 12),
                      ],
                    ),
                    SkeletonBox(width: 70, height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
