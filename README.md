# PHI Smart Inspector

Offline-first field app for Public Health Inspectors in Sri Lanka. Officers log in once, then complete inspections (QR lookup, checklist, geotagged photos, dual signatures, PDF) without a network. Records sync when connectivity returns.

## Stack

- **Mobile:** Flutter + SQLite (`mobile/`)
- **API:** FastAPI (`backend/`)
- **Database:** PostgreSQL 16 (Docker) or SQLite for API tests

## Run the API

```powershell
cd C:\Users\dinuk\Desktop\Projects\PHI
docker compose up --build
```

API: http://127.0.0.1:8000  
Docs: http://127.0.0.1:8000/docs

Demo officer:

- Email: `phi@moh.lk`
- Password: `phi12345`

Without Docker (API only, after Postgres is up):

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
alembic upgrade head
python -m app.seed
uvicorn app.main:app --reload
```

## Run the Flutter app

Flutter SDK is required (`flutter` on PATH). From `mobile/`:

```powershell
# First time only: generate android/ios/windows folders without overwriting lib/
flutter create . --project-name phi_mobile --org lk.gov.moh --platforms android,ios,windows
powershell -File ..\scripts\patch_mobile_permissions.ps1
flutter pub get
flutter run
```

Android emulator talks to the API at `http://10.0.2.2:8000`. Windows/iOS desktop use `http://127.0.0.1:8000`. Override with:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## Offline demo

1. Sign in while online (this pulls premises, checklist, and today's schedule).
2. Enable airplane mode.
3. Open a visit or enter a QR payload (see below).
4. Complete Pass/Fail/N/A, attach a photo, accept the 14-day notice on a Fail, sign twice, generate the PDF.
5. The follow-up appears on the schedule locally.
6. Turn the network back on. The app pushes the outbox (no duplicate inspections).

## Seeded QR payloads

Use these as QR contents or paste them on the scan screen:

| Premises | QR |
| --- | --- |
| Lanka Spice Hotel | `phi://premise/00000000-0000-4000-8000-000000000101` |
| Green Leaf Restaurant | `phi://premise/00000000-0000-4000-8000-000000000102` |
| City Bakery | `phi://premise/00000000-0000-4000-8000-000000000103` |
| Ocean Catch Seafood | `phi://premise/00000000-0000-4000-8000-000000000104` |
| Royal College canteen | `phi://premise/00000000-0000-4000-8000-000000000105` |
| Kade Street Grocery | `phi://premise/00000000-0000-4000-8000-000000000106` |

## Tests

```powershell
cd backend
python -m pytest
```

Flutter (needs SDK):

```powershell
cd mobile
flutter test
```
