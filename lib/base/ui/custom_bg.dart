import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

/// 全 app 自定义背景图：从本地路径读取，叠加半透明遮罩保证文字可读。
class CustomBg {
  static bool get enabled => SpUtil.getBool(spCustomBgEnabled, defValue: false);

  static String get path => SpUtil.getString(spCustomBgPath, defValue: '') ?? '';

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

  static Future<void> setEnabled(bool v) async {
    await SpUtil.putBool(spCustomBgEnabled, v);
  }

  static Future<void> setPath(String p) async {
    await SpUtil.putString(spCustomBgPath, p);
  }

  static Future<void> setDim(double v) async {
    if (v < 0) v = 0;
    if (v > 0.85) v = 0.85;
    await SpUtil.putDouble(spCustomBgDim, v);
  }

  static Future<void> clear() async {
    await SpUtil.putBool(spCustomBgEnabled, false);
    await SpUtil.putString(spCustomBgPath, '');
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(CustomBg.path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        // 遮罩：白天偏白、暗色偏黑，跟随主题亮度
        ColoredBox(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white)
              .withOpacity(dim),
        ),
        // 让子树默认背景透明，才能透出背景图
        Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
          ),
          child: child,
        ),
      ],
    );
  }
}
