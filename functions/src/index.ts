import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// ============================================================
// SUBMIT RIDER APPLICATION
// Creates a disabled Firebase Auth user + rider_applications doc.
// No auth required — the user is creating a new account.
// ============================================================

export const submitRiderApplication = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed." });
      return;
    }

    const {
      email,
      password,
      fullName,
      phone,
      vehicleType,
      vehicleRegistrationNumber,
    } = req.body;

    if (!email || !password || !fullName || !phone || !vehicleType) {
      res.status(400).json({ error: "Missing required fields." });
      return;
    }

    if (password.length < 6) {
      res
        .status(400)
        .json({ error: "Password must be at least 6 characters." });
      return;
    }

    try {
      // Check for duplicate email in rider_applications
      const existingApps = await db
        .collection("rider_applications")
        .where("email", "==", email.trim().toLowerCase())
        .limit(1)
        .get();

      if (!existingApps.empty) {
        res.status(409).json({
          error:
            "An application with this email already exists.",
        });
        return;
      }

      // Check if email already exists in Firebase Auth
      try {
        await auth.getUserByEmail(email.trim().toLowerCase());
        // If we reach here, the user already exists
        res.status(409).json({
          error:
            "An account with this email already exists.",
        });
        return;
      } catch (e: any) {
        // "auth/user-not-found" is expected — means the email is free
        if (e.code !== "auth/user-not-found") {
          throw e;
        }
      }

      // Create Firebase Auth user with disabled=true
      const userRecord = await auth.createUser({
        email: email.trim().toLowerCase(),
        password: password,
        displayName: fullName.trim(),
        disabled: true,
      });

      // Create rider_applications doc
      const appRef = db.collection("rider_applications").doc();
      await appRef.set({
        applicationId: appRef.id,
        uid: userRecord.uid,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        vehicleType: vehicleType,
        vehicleRegistrationNumber:
          (vehicleRegistrationNumber || "").trim(),
        status: "pending",
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        termsAccepted: true,
        rightToWorkConsent: true,
        backgroundCheckConsent: true,
      });

      res.status(200).json({
        success: true,
        applicationId: appRef.id,
        uid: userRecord.uid,
      });
    } catch (error: any) {
      console.error("submitRiderApplication error:", error);

      if (error.code === "auth/email-already-exists") {
        res.status(409).json({
          error: "An account with this email already exists.",
        });
        return;
      }

      res.status(500).json({
        error: "Failed to submit application. Please try again.",
      });
    }
  }
);

// ============================================================
// APPROVE RIDER APPLICATION
// Requires admin authentication.
// Enables the Firebase Auth user + creates users/{uid} doc.
// ============================================================

export const approveRiderApplication = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed." });
      return;
    }

    // Verify admin authentication
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized." });
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];

    let adminUid: string;
    try {
      const decodedToken = await auth.verifyIdToken(idToken);
      adminUid = decodedToken.uid;
    } catch {
      res.status(401).json({ error: "Invalid auth token." });
      return;
    }

    // Verify caller is an admin
    try {
      const adminDoc = await db.collection("users").doc(adminUid).get();
      const adminData = adminDoc.data();
      if (!adminDoc.exists || adminData?.role !== "admin") {
        res.status(403).json({ error: "Access denied. Admin only." });
        return;
      }
    } catch {
      res.status(500).json({ error: "Failed to verify admin." });
      return;
    }

    const { applicationId } = req.body;
    if (!applicationId) {
      res.status(400).json({ error: "Missing applicationId." });
      return;
    }

    try {
      const appRef = db.collection("rider_applications").doc(applicationId);
      const appDoc = await appRef.get();

      if (!appDoc.exists) {
        res.status(404).json({ error: "Application not found." });
        return;
      }

      const appData = appDoc.data()!;

      if (appData.status !== "pending") {
        res.status(400).json({
          error: `Application is already ${appData.status}.`,
        });
        return;
      }

      const riderUid = appData.uid as string;

      // Enable the Firebase Auth user
      await auth.updateUser(riderUid, {
        disabled: false,
      });

      // Create/update users/{uid} doc
      await db.collection("users").doc(riderUid).set({
        uid: riderUid,
        name: appData.fullName,
        email: appData.email,
        phone: appData.phone,
        role: "rider",
        vehicleType: appData.vehicleType,
        vehicleRegistrationNumber: appData.vehicleRegistrationNumber,
        profilePhotoUrl: appData.profilePhotoUrl || null,
        drivingLicenceFrontUrl: appData.drivingLicenceFrontUrl || null,
        drivingLicenceBackUrl: appData.drivingLicenceBackUrl || null,
        accountStatus: "active",
        applicationId: applicationId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Also create/update riders/{uid} doc (for existing admin rider management)
      await db.collection("riders").doc(riderUid).set({
        id: riderUid,
        fullName: appData.fullName,
        email: appData.email,
        phone: appData.phone,
        vehicleType: appData.vehicleType,
        vehicleReg: appData.vehicleRegistrationNumber,
        active: true,
        online: false,
        deliveries: 0,
        currentOrder: null,
        location: "Location unavailable",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update application status
      await appRef.update({
        status: "approved",
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        reviewedBy: adminUid,
      });

      res.status(200).json({ success: true });
    } catch (error: any) {
      console.error("approveRiderApplication error:", error);
      res.status(500).json({
        error: "Failed to approve application.",
      });
    }
  }
);

// ============================================================
// REJECT RIDER APPLICATION
// Requires admin authentication.
// Firebase Auth account stays disabled.
// ============================================================

export const rejectRiderApplication = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed." });
      return;
    }

    // Verify admin authentication
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized." });
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];

    let adminUid: string;
    try {
      const decodedToken = await auth.verifyIdToken(idToken);
      adminUid = decodedToken.uid;
    } catch {
      res.status(401).json({ error: "Invalid auth token." });
      return;
    }

    // Verify caller is an admin
    try {
      const adminDoc = await db.collection("users").doc(adminUid).get();
      const adminData = adminDoc.data();
      if (!adminDoc.exists || adminData?.role !== "admin") {
        res.status(403).json({ error: "Access denied. Admin only." });
        return;
      }
    } catch {
      res.status(500).json({ error: "Failed to verify admin." });
      return;
    }

    const { applicationId, rejectionReason } = req.body;
    if (!applicationId) {
      res.status(400).json({ error: "Missing applicationId." });
      return;
    }

    try {
      const appRef = db.collection("rider_applications").doc(applicationId);
      const appDoc = await appRef.get();

      if (!appDoc.exists) {
        res.status(404).json({ error: "Application not found." });
        return;
      }

      const appData = appDoc.data()!;

      if (appData.status !== "pending") {
        res.status(400).json({
          error: `Application is already ${appData.status}.`,
        });
        return;
      }

      // Firebase Auth account stays disabled — no action needed
      // The disabled account cannot log in

      // Update application status
      await appRef.update({
        status: "rejected",
        rejectionReason: rejectionReason || "",
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        reviewedBy: adminUid,
      });

      res.status(200).json({ success: true });
    } catch (error: any) {
      console.error("rejectRiderApplication error:", error);
      res.status(500).json({
        error: "Failed to reject application.",
      });
    }
  }
);
