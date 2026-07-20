import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

/// 全 app 自定义背景图：从本地路径读取，叠加半透明遮罩保证文字可读。
class CustomBg {
  /// 同路径覆盖文件时强制 Image 刷新
  static int _token = 0;

  static bool get enabled => SpUtil.getBool(spCustomBgEnabled, defValue: false);

  static String get path => SpUtil.getString(spCustomBgPath, defValue: '') ?? '';

  static int get token => _token;

  /// 0.0 最透（图最显）~ 0.85 最深遮罩
  static double get dim {
    final v = SpUtil.getDouble(spCustomBgDim, defValue: 0.45);
    if (v < 0) return 0;
    if (v > 0.85) return 0.85;
    return v;
  }

  static bool get hasImage {
    if (!enabled) return false;
    final p = path;
    if (p.isEmpty) return false;
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// 页面 scaffold 在启用背景时用透明，否则用原色
  static Color? pageBg(Color? normal) => hasImage ? Colors.transparent : normal;

  static Future<void> setEnabled(bool v) async {
    await SpUtil.putBool(spCustomBgEnabled, v);
    _token++;
  }

  static Future<void> setPath(String p) async {
    await SpUtil.putString(spCustomBgPath, p);
    _token++;
  }

  static Future<void> setDim(double v) async {
    if (v < 0) v = 0;
    if (v > 0.85) v = 0.85;
    await SpUtil.putDouble(spCustomBgDim, v);
    _token++;
  }

  static Future<void> clear() async {
    final old = path;
    await SpUtil.putBool(spCustomBgEnabled, false);
    await SpUtil.putString(spCustomBgPath, '');
    _token++;
    if (old.isNotEmpty) {
      try {
        final f = File(old);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
  }
}

/// 包一层：底层背景图 + 遮罩 + 子页面。
class AppBackgroundShell extends StatelessWidget {
  final Widget child;
  final Color? fallbackColor;

  const AppBackgroundShell({
    Key? key,
    required this.child,
    this.fallbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!CustomBg.hasImage) {
      return child;
    }

    final dim = CustomBg.dim;
    final path = CustomBg.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 固定底层，避免子页面白色 scaffold 盖住
        Positioned.fill(
          child: Image.file(
            File(path),
            key: ValueKey('custom_bg_${CustomBg.token}_$path'),
            fit: BoxFit.cover,
            gaplessPlayback: false,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: fallbackColor ?? Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
        // 遮罩：白天偏白、暗色偏黑，跟随主题亮度
        Positioned.fill(
          child: ColoredBox(
            color: (isDark ? Colors.black : Colors.white).withOpacity(dim),
          ),
        ),
        // 强制子树默认 scaffold/canvas 透明，避免各页不设 backgroundColor 时盖住背景
        Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
            cardColor: Theme.of(context).cardColor.withOpacity(0.92),
          ),
          child: child,
        ),
      ],
    );
  }
}
