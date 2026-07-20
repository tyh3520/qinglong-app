import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/module/stats/stats_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  StatsPageState createState() => StatsPageState();
}

class StatsPageState extends ConsumerState<StatsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> refreshKey = GlobalKey();

  bool loading = true;
  bool unsupported = false;
  String? error;

  DashboardOverview overview = DashboardOverview();
  List<TrendPoint> trend = <TrendPoint>[];
  RuntimeOverview runtime = RuntimeOverview();
  List<RankItem> topFail = <RankItem>[];
  List<RankItem> topTime = <RankItem>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 等 home 拉完 system 版本，避免首屏误判
      for (int i = 0; i < 8; i++) {
        if (_trySystemBean() != null) break;
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (mounted) {
        await loadData(showLoading: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  Future<void> move2Top() async {
    if (_scrollController.hasClients &&
        _scrollController.offset != _scrollController.position.minScrollExtent) {
      await scrollToTop();
    } else if (refreshKey.currentState?.mounted ?? false) {
      await refreshKey.currentState?.show();
    } else {
      await loadData(showLoading: false);
    }
  }

  SystemBean? _trySystemBean() {
    try {
      return getIt<SystemBean>(instanceName: getProviderName(context));
    } catch (_) {
      return null;
    }
  }

  Future<void> loadData({bool showLoading = false}) async {
    if (!mounted) return;

    final systemBean = _trySystemBean();
    if (systemBean != null && !systemBean.isUpperVersion2_21_0()) {
      setState(() {
        unsupported = true;
        loading = false;
        error = null;
      });
      return;
    }

    if (showLoading) {
      setState(() {
        loading = true;
        error = null;
        unsupported = false;
      });
    }

    try {
      final api = SingleAccountPageState.ofApi(context);
      final overviewResp = await api.dashboardOverview();
      final trendResp = await api.dashboardTrend(days: 7);
      final runtimeResp = await api.dashboardRuntime();
      final topTimeResp = await api.dashboardTopTime();
      final topCountResp = await api.dashboardTopCount();

      if (!overviewResp.success) {
        final msg = (overviewResp.message ?? '').toLowerCase();
        if (msg.contains('not found') ||
            msg.contains('404') ||
            msg.contains('cannot get') ||
            overviewResp.code == 404) {
          if (!mounted) return;
          setState(() {
            unsupported = true;
            loading = false;
            error = null;
          });
          return;
        }
      }

      final nextOverview = overviewResp.bean ?? DashboardOverview();
      final nextRuntime = runtimeResp.bean ?? RuntimeOverview();
      nextOverview.runningCount = nextRuntime.runningCount;

      final nextTopCount = _parseRank(topCountResp);
      final failCandidates = nextTopCount.where((e) {
        final rate = double.tryParse(e.successRate) ?? 100;
        return rate < 100 || e.failCount > 0;
      }).toList();
      failCandidates.sort((a, b) {
        final af = a.failCount > 0
            ? a.failCount
            : ((100 - (double.tryParse(a.successRate) ?? 100)) * a.runCount).round();
        final bf = b.failCount > 0
            ? b.failCount
            : ((100 - (double.tryParse(b.successRate) ?? 100)) * b.runCount).round();
        return bf.compareTo(af);
      });

      if (!mounted) return;
      setState(() {
        overview = nextOverview;
        runtime = nextRuntime;
        trend = _parseTrend(trendResp);
        topTime = _parseRank(topTimeResp);
        topFail = failCandidates.take(5).toList();
        loading = false;
        error = overviewResp.success ? null : (overviewResp.message ?? '加载失败');
        unsupported = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<TrendPoint> _parseTrend(HttpResponse<String> resp) {
    if (!resp.success || resp.bean == null) return <TrendPoint>[];
    return parseTrendList(resp.bean);
  }

  List<RankItem> _parseRank(HttpResponse<String> resp) {
    if (!resp.success || resp.bean == null) return <RankItem>[];
    return parseRankList(resp.bean);
  }

  Future<void> stopRunning(RunningInstanceItem item) async {
    final id = item.id;
    if (id == null) {
      "无法停止：缺少任务 id".toast();
      return;
    }
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('停止任务'),
        content: Text('确定停止「${item.name}」？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消', style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            child: Text('停止', style: TextStyle(color: ref.read(themeProvider).primaryColor)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final resp = await SingleAccountPageState.ofApi(context).stopTasks([id.toString()]);
    if (resp.success) {
      "已发送停止请求".toast();
      await loadData(showLoading: false);
    } else {
      (resp.message ?? '停止失败').toast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Scaffold(
      appBar: QlAppBar(
        title: '统计',
        canBack: false,
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () => loadData(showLoading: true),
            child: Icon(
              CupertinoIcons.refresh,
              size: 20,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              key: refreshKey,
              onRefresh: () => loadData(showLoading: false),
              child: unsupported
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(CupertinoIcons.chart_bar, size: 42, color: theme.themeColor.descColor()),
                        const SizedBox(height: 16),
                        Text(
                          '当前青龙版本暂不支持任务统计',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.themeColor.titleColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '需要青龙 2.21.0 及以上版本\n（/api/dashboard 系列接口）',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: theme.themeColor.descColor(), height: 1.5),
                        ),
                      ],
                    )
                  : error != null && overview.todayRuns == 0 && trend.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 80),
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.themeColor.descColor()),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => loadData(showLoading: true),
                                child: const Text('重试'),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                          children: [
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  error!,
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                                ),
                              ),
                            _sectionCard(
                              theme,
                              title: '今日运行总览',
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _metric(theme, '总运行', '${overview.todayRuns}')),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _metric(
                                          theme,
                                          '成功率',
                                          '${overview.successRate}%',
                                          valueColor: const Color(0xff3ecf8e),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _metric(
                                          theme,
                                          '成功 / 失败',
                                          '${overview.todaySuccess} / ${overview.todayFail}',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _metric(
                                          theme,
                                          '运行中',
                                          '${runtime.runningCount}',
                                          valueColor: const Color(0xff3ecf8e),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _successBar(theme, overview),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        _healthText(overview),
                                        style: TextStyle(fontSize: 12, color: theme.themeColor.descColor()),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '任务 ${overview.enabled}/${overview.total} 启用',
                                        style: TextStyle(fontSize: 12, color: theme.themeColor.descColor()),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _sectionCard(
                              theme,
                              title: '近 7 天运行趋势',
                              child: trend.isEmpty
                                  ? _emptyLine(theme, '暂无趋势数据')
                                  : _TrendBars(points: trend, theme: theme),
                            ),
                            const SizedBox(height: 12),
                            _sectionCard(
                              theme,
                              title: '运行实例 · ${runtime.runningCount} 个进行中',
                              child: runtime.running.isEmpty
                                  ? _emptyLine(
                                      theme,
                                      runtime.queuedCount > 0
                                          ? '暂无运行中实例，排队 ${runtime.queuedCount}'
                                          : '当前没有运行中的实例',
                                    )
                                  : Column(
                                      children: runtime.running.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: theme.themeColor.titleColor(),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '已运行 ${_formatElapsed(item.elapsed)}'
                                                      '${item.pid != null ? ' · pid ${item.pid}' : ''}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme.themeColor.descColor(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  foregroundColor: Colors.redAccent,
                                                ),
                                                onPressed: () => stopRunning(item),
                                                child: const Text('停止'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            _sectionCard(
                              theme,
                              title: '耗时 Top',
                              child: topTime.isEmpty
                                  ? _emptyLine(theme, '暂无数据')
                                  : Column(
                                      children: topTime.take(5).map((e) {
                                        return _rankRow(
                                          theme,
                                          name: e.name,
                                          desc: '平均 ${_formatMs(e.avgTime)} · 最长 ${_formatMs(e.maxTime)}',
                                        );
                                      }).toList(),
                                    ),
                            ),
                            if (topFail.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _sectionCard(
                                theme,
                                title: '需关注（成功率偏低）',
                                child: Column(
                                  children: topFail.take(5).map((e) {
                                    return _rankRow(
                                      theme,
                                      name: e.name,
                                      desc: '运行 ${e.runCount} · 成功率 ${e.successRate}%',
                                      danger: true,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            if (runtime.idleTasks.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _sectionCard(
                                theme,
                                title: '久未运行',
                                child: Column(
                                  children: runtime.idleTasks.take(5).map((e) {
                                    return _rankRow(
                                      theme,
                                      name: e.name,
                                      desc: '上次 ${e.lastRun}',
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                          ],
                        ),
            ),
    );
  }

  String _healthText(DashboardOverview o) {
    if (o.todayRuns == 0) return '今日暂无运行记录';
    final rate = double.tryParse(o.successRate) ?? 0;
    if (rate >= 90) return '健康度良好';
    if (rate >= 70) return '健康度一般';
    return '失败偏多，建议排查';
  }

  Widget _emptyLine(ThemeViewModel theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(text, style: TextStyle(color: theme.themeColor.descColor(), fontSize: 13)),
      ),
    );
  }

  Widget _sectionCard(ThemeViewModel theme, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.themeColor.settingBgColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.themeColor.settingBordorColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.themeColor.descColor(),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _metric(ThemeViewModel theme, String k, String v, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.themeColor.bg2Color(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: 12, color: theme.themeColor.descColor())),
          const SizedBox(height: 6),
          Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? theme.themeColor.titleColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBar(ThemeViewModel theme, DashboardOverview o) {
    final rate = (double.tryParse(o.successRate) ?? 0).clamp(0, 100) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: o.todayRuns == 0 ? 0 : rate,
        minHeight: 8,
        backgroundColor: theme.themeColor.bg2Color(),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff3ecf8e)),
      ),
    );
  }

  Widget _rankRow(
    ThemeViewModel theme, {
    required String name,
    required String desc,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: danger ? Colors.redAccent : const Color(0xff3ecf8e),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: theme.themeColor.titleColor()),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: theme.themeColor.descColor()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '0s';
    if (ms < 1000) return '${ms}ms';
    final sec = (ms / 1000).round();
    if (sec < 60) return '${sec}s';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m}m${s}s';
  }
}

class _TrendBars extends StatelessWidget {
  final List<TrendPoint> points;
  final ThemeViewModel theme;

  const _TrendBars({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    final maxTotal = points.fold<int>(0, (p, e) => e.total > p ? e.total : p);
    final maxY = maxTotal <= 0 ? 1 : maxTotal;
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((p) {
              final h = (p.total / maxY) * 90.0;
              final failH = p.total == 0 ? 0.0 : (p.fail / p.total) * h;
              final successH = h - failH;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: successH < 0 ? 0 : successH,
                        decoration: BoxDecoration(
                          color: const Color(0xff3ecf8e).withOpacity(0.9),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      Container(
                        height: failH < 2 && p.fail > 0 ? 2 : failH,
                        color: Colors.redAccent.withOpacity(0.85),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: points.map((p) {
            return Expanded(
              child: Text(
                p.date,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: theme.themeColor.descColor()),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          '绿=成功  红=失败',
          style: TextStyle(fontSize: 11, color: theme.themeColor.descColor()),
        ),
      ],
    );
  }
}
