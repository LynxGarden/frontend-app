import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/progress/data/models/progress_models.dart';

/// A theme-aware line chart of a weekly metric. Colors resolve against
/// [AppColors] so the chart flips with light/dark.
class ProgressLineChart extends StatelessWidget {
  const ProgressLineChart({
    super.key,
    required this.points,
    required this.value,
  });

  final List<WeeklyPoint> points;

  /// Selects the y-value from a weekly point (volume or top weight).
  final double Function(WeeklyPoint) value;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.primary;
    final grid = AppColors.surfaceBorder;
    final labelStyle =
        AppTextStyles.label.copyWith(color: AppColors.textTertiary, fontSize: 10);

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), value(points[i])),
    ];
    final maxY = spots.isEmpty
        ? 1.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final fmt = DateFormat('d.M.');

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
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
              reservedSize: 40,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == 0) return const SizedBox.shrink();
                return Text(_compact(v), style: labelStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                // Thin labels on dense charts.
                if (points.length > 6 && i % 2 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(fmt.format(points[i].weekStart), style: labelStyle),
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
                      _compact(s.y),
                      AppTextStyles.label.copyWith(color: AppColors.textPrimary),
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
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: line,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: line.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toStringAsFixed(0);
  }
}
