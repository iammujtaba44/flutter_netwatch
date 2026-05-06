import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import '../models/nw_transaction.dart';

/// Live statistics page showing aggregate metrics across all captured
/// transactions. Useful for spotting hot endpoints and perf regressions
/// without leaving the inspector.
class NWStatsScreen extends StatelessWidget {
  final VoidCallback onClose;

  const NWStatsScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onClose,
            ),
            title: const Text('Stats'),
          ),
          body: StreamBuilder<List<NWTransaction>>(
            stream: NetWatchCore.instance.transactionStream,
            initialData: NetWatchCore.instance.storage.getAll(),
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <NWTransaction>[];
              final stats = _Stats.from(all);
              if (all.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No transactions yet'),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                children: [
                  _SummaryGrid(stats: stats),
                  const SizedBox(height: 16),
                  _DurationCard(stats: stats),
                  const SizedBox(height: 16),
                  _TopEndpointsCard(
                    title: 'Slowest endpoints',
                    icon: Icons.speed,
                    color: const Color(0xFFFFC107),
                    rows: stats.slowestEndpoints,
                    valueLabel: (v) => '${v.toStringAsFixed(0)}ms',
                  ),
                  const SizedBox(height: 16),
                  _TopEndpointsCard(
                    title: 'Most-failing endpoints',
                    icon: Icons.error_outline,
                    color: const Color(0xFFF44336),
                    rows: stats.mostFailingEndpoints,
                    valueLabel: (v) => '${v.toStringAsFixed(0)} fails',
                  ),
                  const SizedBox(height: 16),
                  _HostsCard(rows: stats.hostCounts),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Stats {
  final int total;
  final int success;
  final int failure;
  final int pending;
  final double successRate;
  final double avgDurationMs;
  final double p95DurationMs;
  final double maxDurationMs;
  final List<MapEntry<String, double>> slowestEndpoints;
  final List<MapEntry<String, double>> mostFailingEndpoints;
  final List<MapEntry<String, int>> hostCounts;

  _Stats({
    required this.total,
    required this.success,
    required this.failure,
    required this.pending,
    required this.successRate,
    required this.avgDurationMs,
    required this.p95DurationMs,
    required this.maxDurationMs,
    required this.slowestEndpoints,
    required this.mostFailingEndpoints,
    required this.hostCounts,
  });

  factory _Stats.from(List<NWTransaction> txs) {
    if (txs.isEmpty) {
      return _Stats(
        total: 0,
        success: 0,
        failure: 0,
        pending: 0,
        successRate: 0,
        avgDurationMs: 0,
        p95DurationMs: 0,
        maxDurationMs: 0,
        slowestEndpoints: const [],
        mostFailingEndpoints: const [],
        hostCounts: const [],
      );
    }

    var success = 0;
    var failure = 0;
    var pending = 0;
    final completedDurations = <int>[];
    final endpointDurations = <String, List<int>>{};
    final endpointFailures = <String, int>{};
    final hostCounts = <String, int>{};

    for (final t in txs) {
      if (t.isPending) {
        pending++;
      } else if (t.isError) {
        failure++;
      } else {
        final code = t.statusCode;
        if (code != null && code >= 400) {
          failure++;
        } else {
          success++;
        }
      }

      if (!t.isPending) {
        final ms = t.duration.inMilliseconds;
        completedDurations.add(ms);
        final endpoint = '${t.request.method} ${t.request.url.path}';
        (endpointDurations[endpoint] ??= <int>[]).add(ms);
        if (t.isError ||
            (t.statusCode != null && t.statusCode! >= 400)) {
          endpointFailures[endpoint] = (endpointFailures[endpoint] ?? 0) + 1;
        }
      }

      final host = t.request.url.host;
      if (host.isNotEmpty) {
        hostCounts[host] = (hostCounts[host] ?? 0) + 1;
      }
    }

    final completed = success + failure;
    final successRate = completed == 0 ? 0.0 : success / completed;

    completedDurations.sort();
    final avg = completedDurations.isEmpty
        ? 0.0
        : completedDurations.reduce((a, b) => a + b) /
            completedDurations.length;
    final p95 = _percentile(completedDurations, 95);
    final max = completedDurations.isEmpty
        ? 0.0
        : completedDurations.last.toDouble();

    final slowest = endpointDurations.entries
        .map((e) => MapEntry(
              e.key,
              e.value.reduce((a, b) => a + b) / e.value.length,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostFailing = endpointFailures.entries
        .map((e) => MapEntry(e.key, e.value.toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hostList = hostCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Stats(
      total: txs.length,
      success: success,
      failure: failure,
      pending: pending,
      successRate: successRate,
      avgDurationMs: avg,
      p95DurationMs: p95,
      maxDurationMs: max,
      slowestEndpoints: slowest.take(5).toList(),
      mostFailingEndpoints: mostFailing.take(5).toList(),
      hostCounts: hostList.take(8).toList(),
    );
  }

  static double _percentile(List<int> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted.first.toDouble();
    final rank = (p / 100) * (sorted.length - 1);
    final lower = rank.floor();
    final upper = rank.ceil();
    if (lower == upper) return sorted[lower].toDouble();
    final weight = rank - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }
}

class _SummaryGrid extends StatelessWidget {
  final _Stats stats;

  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '${stats.total}',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Success',
            value: '${stats.success}',
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Failure',
            value: '${stats.failure}',
            color: const Color(0xFFF44336),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Success rate',
            value: '${(stats.successRate * 100).toStringAsFixed(0)}%',
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final _Stats stats;

  const _DurationCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Duration',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DurationStat(label: 'Avg', ms: stats.avgDurationMs),
              const SizedBox(width: 16),
              _DurationStat(label: 'p95', ms: stats.p95DurationMs),
              const SizedBox(width: 16),
              _DurationStat(label: 'Max', ms: stats.maxDurationMs),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationStat extends StatelessWidget {
  final String label;
  final double ms;

  const _DurationStat({required this.label, required this.ms});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${ms.toStringAsFixed(0)}ms',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TopEndpointsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<MapEntry<String, double>> rows;
  final String Function(double) valueLabel;

  const _TopEndpointsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              '—',
              style: TextStyle(color: scheme.onSurfaceVariant),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      valueLabel(row.value),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _HostsCard extends StatelessWidget {
  final List<MapEntry<String, int>> rows;

  const _HostsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = rows.isEmpty
        ? 1
        : rows.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requests by host',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text('—', style: TextStyle(color: scheme.onSurfaceVariant))
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${row.value}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: row.value / maxCount,
                        minHeight: 4,
                        backgroundColor:
                            scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
