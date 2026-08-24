require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');

class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!serviceAccountPath) {
  console.error(
    'Missing GOOGLE_APPLICATION_CREDENTIALS environment variable. ' +
      'Set it to the path of your Firebase service account JSON file.'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
});

const db = admin.firestore();
const serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp();

const app = express();
app.use(cors());
app.use(express.json());

async function requireAdmin(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) {
      return res
        .status(401)
        .json({ error: 'Missing or malformed Authorization header. Expected: Bearer <idToken>.' });
    }

    const decodedToken = await admin.auth().verifyIdToken(token);

    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    if (!userDoc.exists || userDoc.get('role') !== 'admin') {
      return res.status(403).json({ error: 'Admin privileges required.' });
    }

    req.adminUid = decodedToken.uid;
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'Invalid or expired ID token.',
      details: error.message,
    });
  }
}

function generateTemporaryPassword() {
  return `${uuidv4().replace(/-/g, '')}Aa1!`;
}

async function resolveAuthUser(email, contactName) {
  try {
    return await admin.auth().createUser({
      email,
      password: generateTemporaryPassword(),
      displayName: contactName || undefined,
      emailVerified: false,
      disabled: false,
    });
  } catch (error) {
    if (
      error.code === 'auth/email-already-exists' ||
      error.code === 'auth/already-exists'
    ) {
      return admin.auth().getUserByEmail(email);
    }
    throw error;
  }
}

function buildPharmacyProfile(application, uid) {
  return {
    id: uid,
    uid,
    pharmacyName: application.pharmacyName ?? '',
    contactName: application.contactName ?? '',
    email: application.email ?? '',
    phone: application.phone ?? '',
    businessAddress: application.businessAddress ?? '',
    gphcNumber: application.gphcNumber ?? '',
    licenseDocumentUrl: application.licenseDocumentUrl ?? '',
    status: 'Approved',
    active: true,
    createdAt: serverTimestamp(),
  };
}

app.post(
  '/admin/pharmacy-applications/:applicationId/approve',
  requireAdmin,
  async (req, res, next) => {
    const { applicationId } = req.params;
    try {
      const applicationRef = db.collection('pharmacy_applications').doc(applicationId);
      const snapshot = await applicationRef.get();

      if (!snapshot.exists) {
        throw new ApiError(404, `Application "${applicationId}" not found.`);
      }

      const application = snapshot.data();

      if (application.status !== 'pending') {
        throw new ApiError(
          409,
          `Application is not pending (current status: "${application.status}").`
        );
      }

      if (application.accountCreated === true) {
        throw new ApiError(409, 'An account has already been created for this application.');
      }

      if (!application.email) {
        throw new ApiError(422, 'Application has no email address.');
      }

      const userRecord = await resolveAuthUser(application.email, application.contactName);
      const uid = userRecord.uid;

      const passwordResetLink = await admin
        .auth()
        .generatePasswordResetLink(application.email);

      const batch = db.batch();
      batch.update(applicationRef, {
        status: 'approved',
        uid,
        accountCreated: true,
        approvedAt: serverTimestamp(),
        approvedBy: req.adminUid,
      });
      batch.set(
        db.collection('pharmacies').doc(uid),
        buildPharmacyProfile(application, uid),
        { merge: true }
      );
      await batch.commit();

      console.log(`Approved pharmacy application ${applicationId} for ${application.email} (uid: ${uid}).`);

      return res.json({
        success: true,
        message:
          'Pharmacy approved. Auth account ready; deliver the password reset link so the owner can set a password.',
        data: {
          applicationId,
          uid,
          email: application.email,
          accountExisted: Boolean(application.accountCreated),
          passwordResetLink,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

app.post(
  '/admin/pharmacy-applications/:applicationId/reject',
  requireAdmin,
  async (req, res, next) => {
    const { applicationId } = req.params;
    try {
      const applicationRef = db.collection('pharmacy_applications').doc(applicationId);
      const snapshot = await applicationRef.get();

      if (!snapshot.exists) {
        throw new ApiError(404, `Application "${applicationId}" not found.`);
      }

      if (snapshot.data().status !== 'pending') {
        throw new ApiError(
          409,
          `Application is not pending (current status: "${snapshot.data().status}").`
        );
      }

      const rejectionReason =
        typeof req.body?.rejectionReason === 'string' ? req.body.rejectionReason.trim() : '';

      await applicationRef.update({
        status: 'rejected',
        rejectedAt: serverTimestamp(),
        rejectedBy: req.adminUid,
        ...(rejectionReason ? { rejectionReason } : {}),
      });

      console.log(`Rejected pharmacy application ${applicationId}.`);

      return res.json({
        success: true,
        message: 'Pharmacy application rejected.',
        data: { applicationId, status: 'rejected' },
      });
    } catch (error) {
      next(error);
    }
  }
);

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
});

app.use((error, req, res, next) => {
  const status = typeof error.status === 'number' ? error.status : 500;
  if (status >= 500) {
    console.error('Unhandled error:', error);
  }
  res.status(status).json({ error: error.message || 'Internal server error.' });
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`MedsCarrier admin server listening on port ${port}`);
});
