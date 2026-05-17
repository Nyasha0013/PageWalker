# Google Play release — Pagewalker

Package name: **`com.pagewalker.app`**  
Current version: **`6.0.0`** (build **`3`** in `pubspec.yaml` → bump `+N` for each upload)

## 1. One-time: signing key

```bash
chmod +x scripts/android-create-keystore.sh scripts/build-play-release.sh
./scripts/android-create-keystore.sh
```

Back up `pagewalker/android/upload-keystore.jks` and `key.properties` (not in git).

## 2. Release config in the app

Ensure `pagewalker/lib/core/config/env.dart` exists locally with production Supabase anon key and Google Books key (gitignored).

In [Google Cloud Console](https://console.cloud.google.com/) → Credentials → your Books API key:

- Add **Android app** restriction: package `com.pagewalker.app`
- After first Play upload, add **SHA-1** from Play Console → **App integrity** → **Upload key certificate**

Supabase → Authentication → URL configuration → redirect URLs must include:

- `com.pagewalker.app://login-callback`

## 3. Build the App Bundle

```bash
./scripts/build-play-release.sh
```

Upload `pagewalker/build/app/outputs/bundle/release/app-release.aab`.

## 4. Play Console checklist

Create the app (if needed): [Google Play Console](https://play.google.com/console)

| Section | What to provide |
|--------|------------------|
| **App access** | Login required → provide test account (email + password) for reviewers |
| **Ads** | No (unless you add ads later) |
| **Content rating** | Complete IARC questionnaire (book/reading app, user content in reviews/clubs) |
| **Target audience** | 13+ or 18+ per your policy |
| **News app** | No |
| **COVID / government** | No |
| **Data safety** | Account email, profile, library, reviews, reading sessions; Supabase + Google Books search queries; link https://pagewalker.org/privacy |
| **Store listing** | Title **Pagewalker**, short + full description, screenshots (phone 1080×1920 min), feature graphic 1024×500, app icon 512×512 |
| **Privacy policy** | https://pagewalker.org/privacy |
| **Category** | Books & Reference or Lifestyle |
| **Contact** | support@pagewalker.org |

### Permissions (declare in listing / review notes)

- **Internet** — Supabase, book APIs  
- **Camera** — ISBN / cover scanner  
- **Notifications** — reading reminders (optional for user)  
- **Storage (≤ API 32)** — profile photo picker  

### Suggested internal testing first

1. **Release** → **Testing** → **Internal testing** → Create release → upload AAB  
2. Add testers (email list)  
3. Fix crashes / Google Books on device  
4. Promote same release to **Production** → **Closed testing** or **Production**

## 5. Version bumps

Each new upload needs a higher `versionCode` (the number after `+` in pubspec):

```yaml
version: 6.0.0+4   # +4, +5, …
```

Then rebuild and upload a new AAB.

## 6. Reviewer test account

Create a dedicated account, e.g. `playreview@pagewalker.org`, with:

- Email/password sign-in working  
- A few books on TBR / Reading  
- Optional: one public review  

Put credentials in **App access** → **Instructions for reviewers**.
