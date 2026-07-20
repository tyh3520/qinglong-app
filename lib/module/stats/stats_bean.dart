import 'dart:convert';

class DashboardOverview {
  int total;
  int enabled;
  int disabled;
  int todayRuns;
  int todaySuccess;
  int todayFail;
  String successRate;
  int avgTime;
  int runningCount;

  DashboardOverview({
    this.total = 0,
    this.enabled = 0,
    this.disabled = 0,
    this.todayRuns = 0,
    this.todaySuccess = 0,
    this.todayFail = 0,
    this.successRate = '0',
    this.avgTime = 0,
    this.runningCount = 0,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      total: _asInt(json['total']),
      enabled: _asInt(json['enabled']),
      disabled: _asInt(json['disabled']),
      todayRuns: _asInt(json['todayRuns']),
      todaySuccess: _asInt(json['todaySuccess']),
      todayFail: _asInt(json['todayFail']),
      successRate: (json['successRate'] ?? '0').toString(),
      avgTime: _asInt(json['avgTime']),
      runningCount: _asInt(json['runningCount']),
    );
  }
}

class TrendPoint {
  String date;
  int total;
  int success;
  int fail;

  TrendPoint({
    this.date = '',
    this.total = 0,
    this.success = 0,
    this.fail = 0,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: (json['date'] ?? '').toString(),
      total: _asInt(json['total']),
      success: _asInt(json['success']),
      fail: _asInt(json['fail']),
    );
  }
}

class RunningInstanceItem {
  dynamic instanceId;
  dynamic id;
  String name;
  dynamic pid;
  int elapsed;
  String? logPath;

  RunningInstanceItem({
    this.instanceId,
    this.id,
    this.name = '',
    this.pid,
    this.elapsed = 0,
    this.logPath,
  });

  factory RunningInstanceItem.fromJson(Map<String, dynamic> json) {
    return RunningInstanceItem(
      instanceId: json['instanceId'],
      id: json['id'],
      name: (json['name'] ?? '').toString(),
      pid: json['pid'],
      elapsed: _asInt(json['elapsed']),
      logPath: json['logPath']?.toString(),
    );
  }
}

class RuntimeOverview {
  int runningCount;
  int queuedCount;
  List<RunningInstanceItem> running;
  List<IdleTaskItem> idleTasks;

  RuntimeOverview({
    this.runningCount = 0,
    this.queuedCount = 0,
    List<RunningInstanceItem>? running,
    List<IdleTaskItem>? idleTasks,
  })  : running = running ?? <RunningInstanceItem>[],
        idleTasks = idleTasks ?? <IdleTaskItem>[];

  factory RuntimeOverview.fromJson(Map<String, dynamic> json) {
    final runningRaw = json['running'];
    final idleRaw = json['idleTasks'];
    return RuntimeOverview(
      runningCount: _asInt(json['runningCount']),
      queuedCount: _asInt(json['queuedCount']),
      running: runningRaw is List
          ? runningRaw
              .whereType<Map>()
              .map((e) => RunningInstanceItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <RunningInstanceItem>[],
      idleTasks: idleRaw is List
          ? idleRaw
              .whereType<Map>()
              .map((e) => IdleTaskItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <IdleTaskItem>[],
    );
  }
}

class IdleTaskItem {
  dynamic id;
  String name;
  String lastRun;

  IdleTaskItem({
    this.id,
    this.name = '',
    this.lastRun = '-',
  });

  factory IdleTaskItem.fromJson(Map<String, dynamic> json) {
    return IdleTaskItem(
      id: json['id'],
      name: (json['name'] ?? '').toString(),
      lastRun: (json['lastRun'] ?? '-').toString(),
    );
  }
}

class RankItem {
  int rank;
  String name;
  int runCount;
  int avgTime;
  int maxTime;
  String successRate;
  int failCount;

  RankItem({
    this.rank = 0,
    this.name = '',
    this.runCount = 0,
    this.avgTime = 0,
    this.maxTime = 0,
    this.successRate = '0',
    this.failCount = 0,
  });

  factory RankItem.fromJson(Map<String, dynamic> json) {
    return RankItem(
      rank: _asInt(json['rank']),
      name: (json['name'] ?? '').toString(),
      runCount: _asInt(json['runCount']),
      avgTime: _asInt(json['avgTime']),
      maxTime: _asInt(json['maxTime']),
      successRate: (json['successRate'] ?? '0').toString(),
      failCount: _asInt(json['failCount'] ?? json['fail_count']),
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

List<TrendPoint> parseTrendList(dynamic data) {
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {
      return <TrendPoint>[];
    }
  }
  if (data is! List) return <TrendPoint>[];
  return data
      .whereType<Map>()
      .map((e) => TrendPoint.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<RankItem> parseRankList(dynamic data) {
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {
      return <RankItem>[];
    }
  }
  if (data is! List) return <RankItem>[];
  return data
      .whereType<Map>()
      .map((e) => RankItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
