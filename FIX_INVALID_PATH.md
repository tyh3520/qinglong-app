# fix: Invalid path format when opening scripts

## root cause

qinglong server `v2.20.2` added path security middleware in `back/loaders/express.ts`:

```ts
const originalPath = req.path;
const normalizedPath = originalPath.toLowerCase();
if (originalPath !== normalizedPath &&
    (normalizedPath.startsWith('/api/') || normalizedPath.startsWith('/open/'))) {
  return res.status(400).json({ code: 400, message: 'Invalid path format' });
}
```

old app read script content via:

```http
GET /api/scripts/{filename}?path=
```

when `{filename}` is chinese (e.g. `同程旅行.js` / `oppo商城.py`), dio percent-encodes the path with **uppercase hex** (`%E5...`).

after `toLowerCase()`, `%E5` becomes `%e5` → path differs → server returns:

```json
{"code":400,"message":"Invalid path format"}
```

empty `path=` is allowed by server joi; it is **not** the real blocker.

## fix in this repo

change `scriptDetail()` to use query-style endpoint that already exists on qinglong:

```http
GET /api/scripts/detail?file=同程旅行.js&path=
```

url path stays pure lowercase ascii (`/api/scripts/detail`), so the new security middleware never trips.

### files

- `lib/base/http/url.dart` — add `scriptDetailByQuery`
- `lib/base/http/api.dart` — `scriptDetail()` uses query endpoint
- `pubspec.yaml` — version `3.0.1+301`
- `CHANGELOG.md` — note the fix

## build

```bash
cd incoming/qinglong-app
flutter pub get
# android
flutter build apk --release
# ios
flutter build ipa --release
```

## verify

1. open app → scripts
2. open root chinese-named scripts (`同程旅行.js`, `oppo商城.py`)
3. should enter detail/editor without `Invalid path format`
4. optional capture: request should be `/api/scripts/detail?file=...&path=...` and return 200
