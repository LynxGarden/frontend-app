import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/integrations/health_sync_service.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// Daily step totals as a single-series bar chart (last 7 days). Theme-aware:
/// all colors resolve through [AppColors] so it flips with light/dark.
class StepsBarChart extends StatelessWidget {
  const StepsBarChart({super.key, required this.data});

  final List<DailyTotal> data;

  @override
  Widget build(BuildContext context) {
    final bar = AppColors.primary;
    final grid = AppColors.surfaceBorder;
    final labelStyle =
        AppTextStyles.label.copyWith(color: AppColors.textTertiary, fontSize: 10);
    final locale = Localizations.localeOf(context).toString();
    final dow = DateFormat.E(locale);

    final maxY = data.isEmpty
        ? 1.0
        : data.map((d) => d.value.toDouble()).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == 0) return const SizedBox.shrink();
                return Text(compactNumber(v), style: labelStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(dow.format(data[i].day), style: labelStyle),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              compactNumber(rod.toY),
              AppTextStyles.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value.toDouble(),
                  width: 16,
                  color: bar,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sm / 2)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Today's heart-rate curve (bucketed averages) as a single-series line chart.
class HeartRateChart extends StatelessWidget {
  const HeartRateChart({super.key, required this.samples});

  final List<HealthSample> samples;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.primary;
    final grid = AppColors.surfaceBorder;
    final labelStyle =
        AppTextStyles.label.copyWith(color: AppColors.textTertiary, fontSize: 10);

    final spots = <FlSpot>[
      for (final s in samples)
        FlSpot(s.time.hour + s.time.minute / 60.0, s.value),
    ];
    var minY = 40.0, maxY = 120.0;
    if (spots.isNotEmpty) {
      final values = spots.map((s) => s.y);
      minY = (values.reduce((a, b) => a < b ? a : b) - 10).clamp(20, 220);
      maxY = (values.reduce((a, b) => a > b ? a : b) + 10).clamp(40, 230);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text(v.toStringAsFixed(0), style: labelStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 6,
              getTitlesWidget: (v, meta) {
                final h = v.toInt();
                if (h < 0 || h > 24 || h == 24) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$h:00', style: labelStyle),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(0)} bpm',
                      AppTextStyles.label
                          .copyWith(color: AppColors.textPrimary),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: line,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: line.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Short "12.4k" style number for chart labels / stat tiles.
String compactNumber(num v) {
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
  }
  return v.toStringAsFixed(0);
}
