# Samarth Dairy (Flutter + Supabase)

## 1. Backend
1. Create a Supabase project. In SQL Editor run `supabase/migrations/001_schema.sql`, `002_rls.sql`, then `supabase/seed.sql`.
2. Auth > Providers: enable Email (admin) and Phone (customer OTP, e.g. Twilio).
3. Create your admin user (Auth > Users), then run:
   `insert into profiles(id,role,name) values ('<USER_UUID>','admin','Owner') on conflict (id) do update set role='admin';`
4. WhatsApp (optional): `supabase functions deploy send-whatsapp` and
   `supabase secrets set WA_TOKEN=... WA_PHONE_ID=... WA_TEMPLATE=milk_delivered`
   Template body: "Samarth Dairy: Hello {{1}}, {{2}} L milk delivered on {{3}}. Thank you!"
   Without it the app falls back to a wa.me link.

## 2. Build the APK
**No local setup:** push this folder to GitHub, add repo secrets SUPABASE_URL, SUPABASE_ANON_KEY, OWNER_UPI,
run Actions > Build APK, download `samarth-dairy-apk`.

**Local:** install Flutter, then
```
flutter create --platforms=android --org in.samarthdairy --project-name samarth_dairy .
# add INTERNET permission + <queries> for upi/https to android/app/src/main/AndroidManifest.xml (see workflow)
flutter pub get
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=OWNER_UPI=owner@upi
flutter build appbundle --release   # Play Store (needs your own keystore)
```
APK: build/app/outputs/flutter-apk/app-release.apk. The CI build is debug-signed; use your own keystore for Play Store.

## Not yet implemented
Drift offline queue, FCM push, Marathi localisation, biometric lock, Razorpay, Excel export, daily-litres chart, PDF receipts.
