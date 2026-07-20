# 统计 tab 实现说明

## 导航
- 底部顺序：统计 · 定时任务 · 环境变量 · 配置文件 · 我的
- 默认 index=0 → 打开 app 先进统计页
- 原有 4 个 tab 页面内容不改

## 接口（青龙 2.21.0+）
- `GET /api/dashboard/overview`
- `GET /api/dashboard/trend?days=7`
- `GET /api/dashboard/runtime`
- `GET /api/dashboard/top-time`
- `GET /api/dashboard/top-count`
- open 登录同样走 `/open/dashboard/*`（服务端 rewrite）

## 页面
- `lib/module/stats/stats_page.dart`
- `lib/module/stats/stats_bean.dart`

## 版本门槛
- `SystemBean.isUpperVersion2_21_0()`；低于 2.21.0 显示不支持提示
- 接口 404 也会回落为不支持

## 注意
- 你当前线上青龙仍是 2.20.2 时，统计页会提示需升级
- 统计数据依赖服务端任务统计落库；新装/刚升 2.21 可能暂无数据
