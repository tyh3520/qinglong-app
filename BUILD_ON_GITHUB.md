# 用 github actions 编译 apk

## 结论

可以。本仓库已加 workflow：

- `.github/workflows/build-apk.yml`
- 手动触发：`workflow_dispatch`
- 打 tag：`v*` 也会构建，并尝试发 release

## 你需要准备

1. 一个你有写权限的 github 仓库（推荐 fork `ayoulx/qinglong-app` 到你自己账号）
2. 把本机已改好的代码 push 上去
3. 在仓库页：`actions` → `build-apk` → `run workflow`

## 签名（可选）

原项目 release 依赖本地文件：

```text
android/app/qinglong.keystore
```

该文件在 `.gitignore` 里，仓库里没有。

### 有 keystore

仓库 secrets 加：

- `ANDROID_KEYSTORE_BASE64`：keystore 的 base64

生成：

```bash
base64 -w0 android/app/qinglong.keystore
```

当前 `build.gradle` 里写死了：

- storePassword / keyPassword / keyAlias = `jiangyuesong`

如果你的 keystore 密码不同，需要再改 workflow 或 gradle。

### 没有 keystore

workflow 会自动改成 `debug` 签名，仍可装到手机测试（安装包不是原作者正式签名）。

## 本机推送示例

```bash
cd incoming/qinglong-app
# 如果还没 fork，先在 github 网页 fork，再改 remote
git remote set-url origin https://github.com/<你的用户名>/qinglong-app.git

git checkout -b fix/invalid-path-format
git add lib/base/http/api.dart lib/base/http/url.dart pubspec.yaml CHANGELOG.md \
  FIX_INVALID_PATH.md BUILD_ON_GITHUB.md .github/workflows/build-apk.yml
git commit -m "fix: avoid Invalid path format on qinglong 2.20.2 script open"
git push -u origin fix/invalid-path-format
```

然后到 github：

1. actions → build-apk → run workflow
2. 跑完后 artifacts 下载 `qinglong-app-apk`

## 注意

- 当前 openclaw 环境 **没有** github 登录（`gh auth` 未登录），我这边不能直接替你 push / 触发 actions
- 如果你提供 github token（有 `repo` + `workflow` 权限）和目标仓库，我可以代推并触发
