// firebase/functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');

// Initialize Firebase Admin
admin.initializeApp();

// Global constants
const DB = admin.firestore();
const AUTH = admin.auth();
const STORAGE = admin.storage();
const MESSAGING = admin.messaging();

// Utility functions
const { validateInput, sanitizeData } = require('./utils/validation');
const { sendNotification } = require('./utils/notifications');
const paymentProcessor = require('./services/payment-processor');

/**
 * Cloud Function triggers organized by domain
 */

// ==================== AUTHENTICATION TRIGGERS ====================
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  try {
    // Validate and prepare user data
    const userData = {
      uid: user.uid,
      email: user.email,
      displayName: user.displayName || '',
      photoURL: user.photoURL || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      role: 'customer', // Default role
    };

    // Create user document in Firestore
    await DB.collection('users').doc(user.uid).set(userData);

    // Send welcome notification
    await sendNotification({
      userId: user.uid,
      title: 'Welcome to Our App!',
      body: 'Thanks for joining our community.',
    });

    logger.log(`New user created: ${user.uid}`);
  } catch (error) {
    logger.error('Error in onUserCreated:', error);
    throw new HttpsError('internal', 'User creation failed');
  }
});

// ==================== FIRESTORE TRIGGERS ====================
exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    
    try {
      // Validate order data
      validateInput(order, ['userId', 'items', 'totalAmount']);

      // Get seller IDs from products
      const sellerIds = [...new Set(order.items.map(item => item.sellerId))];

      // Send notifications to sellers
      await Promise.all(sellerIds.map(sellerId => 
        sendNotification({
          userId: sellerId,
          title: 'New Order Received',
          body: `Order #${context.params.orderId} for ${order.items.length} items`,
          data: { orderId: context.params.orderId }
        })
      ));

      logger.log(`Order ${context.params.orderId} processed`);
    } catch (error) {
      logger.error('Error in onOrderCreated:', error);
    }
  });

// ==================== PAYMENT PROCESSING ====================
exports.processPayment = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }

  try {
    // Validate payment data
    validateInput(data, ['amount', 'paymentMethod', 'orderId']);
    sanitizeData(data);

    // Process payment
    const result = await paymentProcessor.process({
      userId: context.auth.uid,
      amount: data.amount,
      method: data.paymentMethod,
      orderId: data.orderId,
    });

    // Update order status
    await DB.collection('orders').doc(data.orderId).update({
      paymentStatus: 'completed',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, transactionId: result.transactionId };
  } catch (error) {
    logger.error('Payment processing error:', error);
    throw new HttpsError('internal', error.message);
  }
});

// ==================== SCHEDULED FUNCTIONS ====================
exports.dailyStatsReport = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    try {
      // Calculate daily stats
      const ordersSnapshot = await DB.collection('orders')
        .where('createdAt', '>', new Date(Date.now() - 86400000))
        .get();

      const stats = {
        totalOrders: ordersSnapshot.size,
        totalRevenue: ordersSnapshot.docs.reduce((sum, doc) => sum + doc.data().totalAmount, 0),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Save to stats collection
      await DB.collection('stats').doc().set(stats);

      logger.log('Daily stats report generated');
    } catch (error) {
      logger.error('Error in dailyStatsReport:', error);
    }
  });

// ==================== UTILITY FUNCTIONS ====================
exports.cleanupUserData = functions.https.onCall(async (data, context) => {
  // Admin check
  if (!context.auth || !context.auth.token.admin) {
    throw new HttpsError('permission-denied', 'Admin access required');
  }

  try {
    const userId = data.userId;
    await Promise.all([
      DB.collection('users').doc(userId).delete(),
      AUTH.deleteUser(userId),
      // Add other collections to clean up
    ]);

    return { success: true };
  } catch (error) {
    logger.error('Error in cleanupUserData:', error);
    throw new HttpsError('internal', 'User data cleanup failed');
  }
});