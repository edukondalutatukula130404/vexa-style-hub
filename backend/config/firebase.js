const admin = require('firebase-admin');

let firebaseApp = null;

try {
  if (!admin.apps.length) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID || 'vexa-c0fc4'
        });
      } catch (parseErr) {
        console.warn('⚠️ Invalid FIREBASE_SERVICE_ACCOUNT JSON, falling back to default init:', parseErr.message);
        firebaseApp = admin.initializeApp({
          projectId: process.env.FIREBASE_PROJECT_ID || 'vexa-c0fc4'
        });
      }
    } else {
      firebaseApp = admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'vexa-c0fc4'
      });
    }
    console.log('🔥 Firebase Admin SDK initialized successfully');
  } else {
    firebaseApp = admin.app();
  }
} catch (error) {
  console.warn('⚠️ Firebase Admin SDK initialization notice:', error.message);
}

/**
 * Send targeted FCM Push Notification to specific user devices
 * @param {Object} params
 * @param {string[]} params.tokens - Target user FCM tokens
 * @param {string} params.title - Push notification title
 * @param {string} params.body - Push notification message body
 * @param {Object} params.data - Custom payload (type, orderId, status)
 * @returns {Promise<{ success: boolean, successCount: number, failureCount: number, invalidTokens: string[], reason?: string }>}
 */
const sendFcmNotification = async ({ tokens, title, body, data = {} }) => {
  if (!tokens || tokens.length === 0) {
    return { success: false, successCount: 0, failureCount: 0, invalidTokens: [], reason: 'No FCM tokens registered for user' };
  }

  // Filter out empty or invalid tokens
  const cleanTokens = Array.from(
    new Set(tokens.filter(t => t && typeof t === 'string' && t.trim().length > 10).map(t => t.trim()))
  );

  if (cleanTokens.length === 0) {
    return { success: false, successCount: 0, failureCount: 0, invalidTokens: [], reason: 'No valid FCM tokens' };
  }

  // Ensure all data values are stringified for FCM
  const payloadData = {};
  for (const [key, value] of Object.entries(data)) {
    payloadData[key] = String(value ?? '');
  }

  const message = {
    notification: {
      title,
      body
    },
    data: payloadData,
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        sound: 'default',
        priority: 'max',
        visibility: 'public'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true
        }
      }
    }
  };

  const invalidTokens = [];
  let successCount = 0;
  let failureCount = 0;

  try {
    if (admin.apps.length && admin.messaging) {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: cleanTokens,
        ...message
      });

      response.responses.forEach((resp, idx) => {
        if (resp.success) {
          successCount++;
        } else {
          failureCount++;
          const errCode = resp.error?.code || '';
          console.warn(`FCM send error for token [${cleanTokens[idx].slice(0, 10)}...]:`, resp.error?.message || errCode);
          if (
            errCode === 'messaging/registration-token-not-registered' ||
            errCode === 'messaging/invalid-registration-token' ||
            errCode === 'messaging/invalid-argument'
          ) {
            invalidTokens.push(cleanTokens[idx]);
          }
        }
      });

      console.log(`🚀 FCM Push Notification Sent: ${successCount} succeeded, ${failureCount} failed.`);
      return {
        success: successCount > 0,
        successCount,
        failureCount,
        invalidTokens
      };
    }
  } catch (error) {
    console.warn('⚠️ FCM Multicast send error:', error.message);
  }

  return { success: false, successCount: 0, failureCount: 0, invalidTokens: [], reason: 'FCM SDK messaging unconfigured' };
};

module.exports = {
  admin,
  sendFcmNotification
};
