# MedsCarrier Admin Server

Express backend for the MedsCarrier pharmacy approval workflow. Handles privileged operations that cannot run from the Flutter client (Firebase Auth account creation, password reset links) using the Firebase Admin SDK.

## Endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | Health check |
| `POST` | `/admin/pharmacy-applications/:applicationId/approve` | Approve a pending pharmacy application |
| `POST` | `/admin/pharmacy-applications/:applicationId/reject` | Reject a pending pharmacy application |

All `/admin/*` routes require a Firebase ID token in the `Authorization: Bearer <idToken>` header. The token is verified with `admin.auth().verifyIdToken()`, and the caller must have `role == 'admin'` in their Firestore document at `users/{uid}`.

## Setup

1. Install dependencies:

   ```bash
   cd server
   npm install
   ```

2. Create a service account key:

   - Firebase Console -> Project settings -> Service accounts -> Generate new private key.
   - Save the JSON file locally, e.g. `server/serviceAccountKey.json`.
   - **Never commit this file** (already covered by `server/.gitignore`).

3. Configure environment variables:

   ```bash
   cp .env.example .env
   ```

   | Variable | Required | Description |
   | --- | --- | --- |
   | `GOOGLE_APPLICATION_CREDENTIALS` | Yes | Path to the service account JSON file |
   | `PORT` | No | HTTP port (default `3000`) |

4. Run:

   ```bash
   npm start        # production
   npm run dev      # watch mode (Node 18+)
   ```

## Approve workflow

`POST /admin/pharmacy-applications/:applicationId/approve`

1. Verifies admin auth (ID token + `role == 'admin'`).
2. Loads `pharmacy_applications/{applicationId}`; fails if status is not `"pending"` or `accountCreated` is already `true`.
3. Creates a Firebase Auth user for the application email (if an Auth user already exists for that email, reuses the existing UID).
4. Generates a password reset link via `admin.auth().generatePasswordResetLink()` so the pharmacy owner can set their own password. The link is returned in the response for the admin to deliver; wire up an email provider (e.g. Firebase's built-in email templates or SendGrid) if automated delivery is desired.
5. Atomically (single batched write):
   - Updates the application: `status: "approved"`, `uid`, `accountCreated: true`, `approvedAt`, `approvedBy`.
   - Creates/merges `pharmacies/{uid}` with: `id`, `uid`, `pharmacyName`, `contactName`, `email`, `phone`, `businessAddress`, `gphcNumber`, `licenseDocumentUrl`, `status: 'Approved'`, `active: true`, `createdAt`.

Example:

```bash
curl -X POST http://localhost:3000/admin/pharmacy-applications/abc123/approve \
  -H "Authorization: Bearer <adminIdToken>"
```

## Reject workflow

`POST /admin/pharmacy-applications/:applicationId/reject`

Sets `status: "rejected"`, `rejectedAt`, `rejectedBy`, and optionally stores a `rejectionReason` from the JSON body. Fails if the application is not pending.

```bash
curl -X POST http://localhost:3000/admin/pharmacy-applications/abc123/reject \
  -H "Authorization: Bearer <adminIdToken>" \
  -H "Content-Type: application/json" \
  -d '{"rejectionReason": "License document could not be verified"}'
```

## Error responses

All errors return JSON of the form `{ "error": "<message>" }` with appropriate status codes: `401` (bad/missing token), `403` (not an admin), `404` (unknown application), `409` (conflict — not pending or already processed), `422` (missing application data), `500` (unexpected).

## Security notes

- No credentials are hardcoded; everything comes from the environment/service account file.
- Deploy behind HTTPS only. The CORS policy currently allows all origins since clients authenticate via Firebase ID tokens; restrict origins if needed.
- Restrict the service account to the minimum IAM roles required (Firebase Admin + Auth Admin on the project).
