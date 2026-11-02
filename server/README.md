# Kuruvi — Hostinger setup

Everything here is uploaded to Hostinger. Three things to do: publish the legal
documents, deploy the OTP API, then point the app at your domain.

---

## 1. Publish the legal documents

Upload the two files from the project's `legal/` folder:

| Local file           | Upload to                       |
| -------------------- | ------------------------------- |
| `legal/terms.html`   | `public_html/legal/terms.html`   |
| `legal/privacy.html` | `public_html/legal/privacy.html` |

In hPanel: **Files → File Manager → public_html**, create a `legal` folder, drop
both files in.

Check they load:

- `https://yourdomain.com/legal/terms.html`
- `https://yourdomain.com/legal/privacy.html`

### Fill in the placeholders first

Both documents have gaps highlighted in yellow. Search for `____` and
`[Company Address]` and replace them:

- **Effective Date** — in both files.
- **Company Address** — in both files.
- **Contact email** — `terms.html` currently says `legal@xapp.com`, which looks
  like leftover template text from the source `.docx`. It is almost certainly
  wrong; change it to a real Kuruvi address.
- **Privacy contact** — `privacy.html` has `[privacy@yourdomain.com]`.

---

## 2. Deploy the OTP API

Upload all four PHP files to `public_html/server/`:

```
public_html/server/config.php
public_html/server/mailer.php
public_html/server/send_otp.php
public_html/server/verify_otp.php
```

### Edit `config.php`

| Setting      | What to put                                                     |
| ------------ | --------------------------------------------------------------- |
| `API_KEY`    | A long random string. Must match `AppConfig.apiKey` in the app.  |
| `APP_SECRET` | A **different** long random string. Server-only; never shipped.  |
| `MAIL_FROM`  | An address on your own domain, e.g. `no-reply@yourdomain.com`.   |

Generate the two secrets with:

```bash
openssl rand -hex 32
```

### Storage directory

`STORAGE_DIR` defaults to `../../kuruvi_otp_store` — a sibling of
`public_html`, so OTP records are **not reachable over HTTP**. It is created
automatically on first use.

If your plan won't let PHP write outside `public_html`, point it somewhere else
outside the web root. Never put it inside `public_html` — the records would be
downloadable.

### Email delivery

`mail()` does **not** work from a `*.hostingersite.com` preview domain. The
domain has no MX, SPF or DKIM record, so Gmail silently drops the message —
`mail()` still returns success, because PHP only hands it to the local MTA.

So `MAILER` defaults to **Brevo**, which lets you send from a single verified
address without owning a domain. Free tier is 300 emails/day.

**Setup (about 5 minutes):**

1. Sign up at <https://www.brevo.com> (free, no card).
2. **Senders, Domains & Dedicated IPs → Senders → Add a sender.** Enter the
   address you want mail to come from (a Gmail address is fine). Brevo emails
   you a confirmation link — click it.
3. **SMTP & API → API Keys → Generate a new API key.** Copy it (starts `xkeysib-`).
4. In `config.php` set:
   ```php
   const MAILER         = 'brevo';
   const MAILER_API_KEY = 'xkeysib-...';
   const MAIL_FROM      = 'the address you verified in step 2';
   ```
5. Re-upload `config.php`, `send_otp.php` and `mailer.php`.

`MAILER` also accepts `'resend'` (Resend.com, 3,000/month free) or `'mail'`
once you have a real domain with SPF set up.

**While setting up,** `DEBUG_SEND = true` returns the provider's actual error
in the JSON response, so a failed send tells you why. Set it to `false` once
mail is working.

---

## 3. Point the app at your domain

Edit `lib/config/app_config.dart`:

```dart
static const String siteBaseUrl = 'https://yourdomain.com';
static const String apiKey      = '<the same API_KEY from config.php>';
```

Then rebuild. Until `siteBaseUrl` is set, the app shows a clear "not published
yet" message instead of a confusing network error.

---

## 4. Verify

```bash
# should return {"ok":true,"expires_in":600}
curl -X POST https://yourdomain.com/server/send_otp.php \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -d '{"email":"you@example.com"}'

# should return {"ok":true,"proof":"..."}
curl -X POST https://yourdomain.com/server/verify_otp.php \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -d '{"email":"you@example.com","code":"123456"}'
```

Without the `X-Api-Key` header both should return `401 unauthorized`.

---

## What the server enforces

- Only a **hash** of each code is stored, never the code itself.
- Codes expire after `OTP_TTL_MINUTES` (default 10).
- Max `OTP_MAX_ATTEMPTS` wrong guesses (default 5), then the code is burned.
- 60-second cooldown between sends to one address.
- Max 20 sends per IP per hour.
- Correct codes are deleted immediately, so they can't be replayed.
- Expired records are swept automatically.

## Known limitation — read this

The app calls Firebase directly to create the account once it holds a `proof`
from `verify_otp.php`. Firebase itself doesn't check that proof, so a modified
client could skip verification and register an unverified address.

This stops casual abuse, not a determined attacker. To close it properly, the
account must be created **server-side**:

1. `composer require kreait/firebase-php` on the server.
2. Add a Firebase service-account JSON (outside `public_html`).
3. After verifying the OTP, have PHP create the user and return a **custom
   token**.
4. The app signs in with `signInWithCustomToken` instead of
   `createUserWithEmailAndPassword`.

That makes the OTP genuinely mandatory, because only the server can mint accounts.
