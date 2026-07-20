# 仪表盘 tab 实现说明（对齐网页版）

## 导航
- 底部顺序：仪表盘 · 定时任务 · 环境变量 · 配置文件 · 我的
- 默认 index=0 → 打开 app 先进仪表盘
- 原有 4 个 tab 页面内容不改

## 布局（对齐青龙网页版 dashboard）
1. 8 项总览卡：总任务 / 已启用 / 今日执行 / 成功率 / 今日成功 / 今日失败 / 平均耗时 / 已禁用
2. 近 7 日趋势（总执行 / 成功 / 失败 折线+浅色面积）
3. 今日耗时 Top 5
4. 今日执行次数 Top 5
5. 标签统计（有数据才显示）
6. 实时运行态（运行中/排队 + 停止 + 24h 未运行）
7. 系统资源（内存表盘 / 运行时长 / 堆 / 负载 / CPU / 平台）

## 接口（青龙 2.21.0+）
- `GET /api/dashboard/overview`
- `GET /api/dashboard/trend?days=7`
- `GET /api/dashboard/runtime`
- `GET /api/dashboard/top-time`
- `GET /api/dashboard/top-count`
- `GET /api/dashboard/system`
- `GET /api/dashboard/labels`
- open 登录同样走 `/open/dashboard/*`

## 页面
- `lib/module/stats/stats_page.dart`
- `lib/module/stats/stats_bean.dart`

## 自定义背景图（全 app）
- 入口：我的 → 系统设置 → 通用功能
- 能力：开关 / 选图 / 遮罩强度 / 清除
- 存储：`spCustomBgEnabled` / `spCustomBgPath` / `spCustomBgDim`
- 图片复制到 app 文档目录 `custom_app_bg.*`，避免临时路径失效
- 渲染：`AppBackgroundShell` 挂在 `MaterialApp.builder`，全路由生效
- 首页 / 设置 / 仪表盘在有背景时 scaffold 透明，卡片半透明

## 版本门槛
- `SystemBean.isUpperVersion2_21_0()`；低于 2.21.0 显示不支持提示
- 接口 404 也会回落为不支持

## 注意
- 你当前线上青龙仍是 2.20.2 时，仪表盘会提示需升级
- 统计数据依赖服务端任务统计落库；新装/刚升 2.21 可能暂无数据
