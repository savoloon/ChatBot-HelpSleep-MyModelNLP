import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/features/sleep_insights/domain/entities/sleep_insight.dart';
import 'package:mobile/features/sleep_insights/presentation/state/sleep_insights_controller.dart';

class SleepInsightsPage extends StatefulWidget {
  const SleepInsightsPage({required this.controller, super.key});

  final SleepInsightsController controller;

  @override
  State<SleepInsightsPage> createState() => _SleepInsightsPageState();
}

class _SleepInsightsPageState extends State<SleepInsightsPage> {
  SleepInsight? _selectedInsight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Sleep Insights'),
          ),
          body: RefreshIndicator(
            onRefresh: widget.controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                _PeriodFilter(
                  selected: widget.controller.period,
                  onChange: widget.controller.changePeriod,
                ),
                const SizedBox(height: 12),
                if (widget.controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (widget.controller.error != null)
                  _ErrorState(
                    message: widget.controller.error!,
                    onRetry: widget.controller.refresh,
                  )
                else if (widget.controller.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text('Пока нет данных о сне за выбранный период.'),
                    ),
                  )
                else ...[
                  _SummaryCard(items: widget.controller.items),
                  const SizedBox(height: 10),
                  _DurationBarChart(
                    items: widget.controller.items,
                    selectedInsight: _resolveSelected(widget.controller.items),
                    onSelect: (item) {
                      setState(() {
                        _selectedInsight = item;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_resolveSelected(widget.controller.items) != null)
                    _SelectedDayCard(
                        item: _resolveSelected(widget.controller.items)!),
                  const SizedBox(height: 12),
                  ...widget.controller.items.take(30).map(
                        (item) => Card(
                          child: ListTile(
                            title: Text(_formatDate(item.date)),
                            subtitle: Text(item.schedule ?? 'График не указан'),
                            trailing:
                                Text('${item.duration.toStringAsFixed(1)} ч'),
                            onTap: () {
                              setState(() {
                                _selectedInsight = item;
                              });
                            },
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  SleepInsight? _resolveSelected(List<SleepInsight> items) {
    if (items.isEmpty) return null;
    if (_selectedInsight == null) return items.last;
    for (final item in items) {
      if (item.id == _selectedInsight!.id) return item;
    }
    return items.last;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});

  final List<SleepInsight> items;

  @override
  Widget build(BuildContext context) {
    final average = items.isEmpty
        ? 0.0
        : items.map((e) => e.duration).reduce((a, b) => a + b) / items.length;
    final status = _statusByAverage(average);
    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Средняя длительность сна: ${average.toStringAsFixed(1)} ч',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Оценка периода: $status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                const _LegendRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusByAverage(double value) {
    if (value < 6 || value > 12) return 'Риск';
    if ((value >= 6 && value < 8) || (value > 10 && value <= 12)) {
      return 'Внимание';
    }
    return 'Норма';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Риск':
        return const Color(0xFFE74C3C);
      case 'Внимание':
        return const Color(0xFFF1C40F);
      default:
        return const Color(0xFF2ECC71);
    }
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        _LegendItem(color: Color(0xFFE74C3C), label: '< 6ч или > 12ч'),
        _LegendItem(color: Color(0xFFF1C40F), label: '6-8ч или 10-12ч'),
        _LegendItem(color: Color(0xFF2ECC71), label: '8-10ч'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.selected, required this.onChange});

  final SleepInsightsPeriod selected;
  final ValueChanged<SleepInsightsPeriod> onChange;

  @override
  Widget build(BuildContext context) {
    final entries = <(SleepInsightsPeriod, String)>[
      (SleepInsightsPeriod.week, '7 дней'),
      (SleepInsightsPeriod.month, 'Месяц'),
      (SleepInsightsPeriod.halfYear, 'Полгода'),
      (SleepInsightsPeriod.year, 'Год'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.$2),
                  selected: selected == entry.$1,
                  onSelected: (_) => onChange(entry.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DurationBarChart extends StatelessWidget {
  const _DurationBarChart({
    required this.items,
    required this.selectedInsight,
    required this.onSelect,
  });

  final List<SleepInsight> items;
  final SleepInsight? selectedInsight;
  final ValueChanged<SleepInsight> onSelect;

  @override
  Widget build(BuildContext context) {
    final viewItems =
        items.length > 20 ? items.sublist(items.length - 20) : items;
    final maxDuration = viewItems
        .map((e) => e.duration)
        .fold<double>(0, (prev, el) => el > prev ? el : prev)
        .clamp(1, 16)
        .toDouble();
    final yMax = math.max(12.0, (maxDuration + 1).ceilToDouble());

    final average = viewItems.map((e) => e.duration).reduce((a, b) => a + b) /
        viewItems.length;
    final averageFactor = (average / yMax).clamp(0.0, 1.0);

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Длительность сна',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Среднее: ${average.toStringAsFixed(1)}ч',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxHeight - 24;
                final averageBottom = chartHeight * averageFactor;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${yMax.toInt()}',
                              style: Theme.of(context).textTheme.labelSmall),
                          Text((yMax * 0.75).toStringAsFixed(0),
                              style: Theme.of(context).textTheme.labelSmall),
                          Text((yMax * 0.5).toStringAsFixed(0),
                              style: Theme.of(context).textTheme.labelSmall),
                          Text((yMax * 0.25).toStringAsFixed(0),
                              style: Theme.of(context).textTheme.labelSmall),
                          Text('0',
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: math.max(viewItems.length * 28.0,
                              constraints.maxWidth - 38),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    5,
                                    (_) => Container(
                                      height: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.45),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: averageBottom,
                                child: Container(
                                  height: 1.8,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.7),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children:
                                    viewItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final factor =
                                      (item.duration / yMax).clamp(0.04, 1.0);
                                  final barAreaHeight = chartHeight - 18;
                                  final barHeight = (barAreaHeight * factor)
                                      .clamp(8.0, barAreaHeight);
                                  final isSelected =
                                      selectedInsight?.id == item.id;
                                  final showDate = index % 2 == 0 || isSelected;

                                  return SizedBox(
                                    width: 28,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: InkWell(
                                        onTap: () => onSelect(item),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (isSelected)
                                              Text(
                                                item.duration
                                                    .toStringAsFixed(1),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700),
                                              )
                                            else
                                              const SizedBox(height: 14),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              height: barAreaHeight,
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 180),
                                                  curve: Curves.easeOut,
                                                  height: barHeight,
                                                  width: isSelected ? 16 : 12,
                                                  decoration: BoxDecoration(
                                                    color: _durationColor(
                                                        item.duration),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7),
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: Colors.black,
                                                            width: 1.2)
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              showDate
                                                  ? '${item.date.day.toString().padLeft(2, '0')}.${item.date.month.toString().padLeft(2, '0')}'
                                                  : ' ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _durationColor(double duration) {
    if (duration < 6 || duration > 12) return const Color(0xFFE74C3C);
    if ((duration >= 6 && duration < 8) || (duration > 10 && duration <= 12)) {
      return const Color(0xFFF1C40F);
    }
    return const Color(0xFF2ECC71);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Text(message,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.item});

  final SleepInsight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбранный день: ${_formatDate(item.date)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text('Сон: ${item.duration.toStringAsFixed(1)} ч'),
          Text('Период: ${item.schedule ?? 'График не указан'}'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}
