import 'package:json_conversion_annotation/json_conversion_annotation.dart';

@JsonConversion()
class SystemBean {
  String? version;
  bool? fromAutoGet = true;

  SystemBean({
    this.version,
    this.fromAutoGet,
  });

  SystemBean.fromJson(Map<String, dynamic> json) {
    version = json['version'];
  }

  //2.13.9 以及以上版本,任务列表 api 变化
  bool isUpperVersion2_13_9() {
    try {
      List<String>? version1 = version?.split("\.");

      String f = version1?[0] ?? "2";
      String s = version1?[1] ?? "10";
      String t = version1?[2] ?? "0";

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) >= 021309) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  //2.12.2 以及以上版本,日志从dirs换成了data
  bool isUpperVersion2_12_2() {
    try {
      List<String>? version1 = version?.split("\.");

      String f = version1?[0] ?? "2";
      String s = version1?[1] ?? "10";
      String t = version1?[2] ?? "0";

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) >= 021202) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  //2.14.5 以及以上版本日志可以删除
  bool isUpperVersion2_14_5() {
    try {
      List<String>? version1 = version?.split("\.");

      String f = version1?[0] ?? "2";
      String s = version1?[1] ?? "10";
      String t = version1?[2] ?? "0";

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) >= 021405) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  //2.13.0 以及以上版本日志详情接口参数有变化
  bool isUpperVersion2_13_0() {
    try {
      List<String>? version1 = version?.split("\.");

      String f = version1?[0] ?? "2";
      String s = version1?[1] ?? "10";
      String t = version1?[2] ?? "0";

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) >= 021300) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  //2.14.0 以及列表不用排序
  bool isUpperVersion2_14_0() {
    try {
      List<String>? version1 = version?.split("\.");

      String f = version1?[0] ?? "2";
      String s = version1?[1] ?? "10";
      String t = version1?[2] ?? "0";

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) >= 021400) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // 2.10.13以上版本,针对任务,环境变量编辑做了修改
  bool isUpperVersion() {
    try {
      List<String>? version1 = version?.split("\.");

      String f = version1?[0] ?? "2";
      String s = version1?[1] ?? "10";
      String t = version1?[2] ?? "0";

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) > 021013) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }


  // 2.21.0 以及以上版本, 支持任务统计 / 运行实例 dashboard
  bool isUpperVersion2_21_0() {
    try {
      // 兼容 "v2.20.2" / "2.20.2-xxx" 等格式
      final raw = (version ?? '').trim();
      final m = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(raw);
      String f;
      String s;
      String t;
      if (m != null) {
        f = m.group(1)!;
        s = m.group(2)!;
        t = m.group(3)!;
      } else {
        List<String>? version1 = raw.split(".");
        f = version1.isNotEmpty ? version1[0].replaceAll(RegExp(r'[^0-9]'), '') : "2";
        s = version1.length > 1 ? version1[1].replaceAll(RegExp(r'[^0-9]'), '') : "10";
        t = version1.length > 2 ? version1[2].replaceAll(RegExp(r'[^0-9]'), '') : "0";
        if (f.isEmpty) f = "2";
        if (s.isEmpty) s = "10";
        if (t.isEmpty) t = "0";
      }

      if (f.length == 1) {
        f = "0$f";
      }
      if (s.length == 1) {
        s = "0$s";
      }
      if (t.length == 1) {
        t = "0$t";
      }

      String tempSum = "$f$s$t";

      if ((int.tryParse(tempSum) ?? 1) >= 022100) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['version'] = this.version;
    return data;
  }

  static SystemBean jsonConversion(Map<String, dynamic> json) {
    return SystemBean.fromJson(json);
  }
}

