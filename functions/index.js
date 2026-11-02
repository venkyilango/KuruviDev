/**
 * Kuruvi push notification triggers.
 *
 * Fires server-side whenever a message document is created, so a notification
 * is sent even if the sender's app is killed the moment after sending.
 *
 * Collections involved:
 *   chats/{chatId}                  { participants: [uidA, uidB] }
 *   chats/{chatId}/messages/{id}    { senderId, message, timestamp, isRead }
 *
 *   travel_groups/{groupId}         { participants: [...], restrictedUsers: [...] }
 *   travel_groups/{groupId}/messages/{id} { senderId, senderName, text }
 *
 *   users/{uid}                     { username, fcmTokens: [...] }
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');

initializeApp();
const db = getFirestore();

// Keep cold starts and cost down; these are tiny functions.
setGlobalOptions({ region: 'asia-south1', maxInstances: 10, memory: '256MiB' });

/** Notification body preview — long messages get truncated. */
function preview(text, max = 120) {
  const t = (text || '').replace(/\s+/g, ' ').trim();
  if (!t) return 'Sent an attachment';
  return t.length > max ? `${t.slice(0, max - 1)}…` : t;
}

/** Collects the FCM tokens for a set of uids, skipping users with none. */
async function tokensFor(uids) {
  if (uids.length === 0) return new Map();

  // getAll has no 10-item limit, unlike an `in` query.
  const refs = uids.map((uid) => db.collection('users').doc(uid));
  const snaps = await db.getAll(...refs);

  const byUid = new Map();
  for (const snap of snaps) {
    if (!snap.exists) continue;
    const tokens = snap.get('fcmTokens');
    if (Array.isArray(tokens) && tokens.length > 0) {
      byUid.set(snap.id, [...new Set(tokens)]);
    }
  }
  return byUid;
}

/** Looks up a display name, falling back to something neutral. */
async function displayName(uid, fallback) {
  if (fallback) return fallback;
  try {
    const snap = await db.collection('users').doc(uid).get();
    return snap.get('username') || 'Someone';
  } catch (err) {
    logger.warn('could not read username', { uid, err: err.message });
    return 'Someone';
  }
}

/**
 * Sends to every token and removes the ones FCM reports as dead, so a user's
 * token list doesn't grow stale after reinstalls.
 */
async function sendAndPrune(tokensByUid, payload) {
  const allTokens = [];
  const ownerOf = new Map();

  for (const [uid, tokens] of tokensByUid) {
    for (const t of tokens) {
      allTokens.push(t);
      ownerOf.set(t, uid);
    }
  }

  if (allTokens.length === 0) {
    logger.info('no tokens to notify');
    return;
  }

  const res = await getMessaging().sendEachForMulticast({
    tokens: allTokens,
    notification: payload.notification,
    data: payload.data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'kuruvi_default',
        sound: 'default',
      },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
  });

  logger.info('push sent', {
    success: res.successCount,
    failure: res.failureCount,
    recipients: tokensByUid.size,
  });

  // Prune tokens FCM says are permanently invalid.
  const dead = new Map();
  res.responses.forEach((r, i) => {
    if (r.success) return;
    const code = r.error?.code || '';
    const gone =
      code.includes('registration-token-not-registered') ||
      code.includes('invalid-registration-token') ||
      code.includes('invalid-argument');

    if (gone) {
      const token = allTokens[i];
      const uid = ownerOf.get(token);
      if (!dead.has(uid)) dead.set(uid, []);
      dead.get(uid).push(token);
    } else {
      logger.warn('push failed', { code, detail: r.error?.message });
    }
  });

  await Promise.all(
    [...dead].map(([uid, tokens]) =>
      db
        .collection('users')
        .doc(uid)
        .update({ fcmTokens: FieldValue.arrayRemove(...tokens) })
        .catch((err) => logger.warn('prune failed', { uid, err: err.message }))
    )
  );
}

/* -------------------------------------------------------------------------- */
/*                             ONE-TO-ONE CHAT                                */
/* -------------------------------------------------------------------------- */

exports.onDirectMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const msg = event.data?.data();
    if (!msg) return;

    const { chatId } = event.params;
    const senderId = msg.senderId;
    if (!senderId) return;

    const chatSnap = await db.collection('chats').doc(chatId).get();
    const participants = chatSnap.get('participants') || [];

    const recipients = participants.filter((uid) => uid !== senderId);
    if (recipients.length === 0) return;

    const [name, tokensByUid] = await Promise.all([
      displayName(senderId, msg.senderName),
      tokensFor(recipients),
    ]);

    await sendAndPrune(tokensByUid, {
      notification: {
        title: name,
        body: preview(msg.message ?? msg.text),
      },
      data: {
        type: 'chat',
        chatId,
        senderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });
  }
);

/* -------------------------------------------------------------------------- */
/*                               GROUP CHAT                                   */
/* -------------------------------------------------------------------------- */

exports.onGroupMessage = onDocumentCreated(
  'travel_groups/{groupId}/messages/{messageId}',
  async (event) => {
    const msg = event.data?.data();
    if (!msg) return;

    const { groupId } = event.params;
    const senderId = msg.senderId;
    if (!senderId) return;

    const groupSnap = await db.collection('travel_groups').doc(groupId).get();
    if (!groupSnap.exists) return;

    const participants = groupSnap.get('participants') || [];
    const restricted = groupSnap.get('restrictedUsers') || [];

    // Don't notify the sender, or anyone restricted from the group.
    const recipients = participants.filter(
      (uid) => uid !== senderId && !restricted.includes(uid)
    );
    if (recipients.length === 0) return;

    const from = groupSnap.get('fromLocation');
    const to = groupSnap.get('toLocation');
    const groupLabel = from && to ? `${from} → ${to}` : 'Group trip';

    const [name, tokensByUid] = await Promise.all([
      displayName(senderId, msg.senderName),
      tokensFor(recipients),
    ]);

    await sendAndPrune(tokensByUid, {
      notification: {
        title: groupLabel,
        body: `${name}: ${preview(msg.text ?? msg.message)}`,
      },
      data: {
        type: 'group',
        groupId,
        senderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });
  }
);

/* -------------------------------------------------------------------------- */
/*                            BOOKING REQUESTS                                */
/* -------------------------------------------------------------------------- */

exports.onBookingRequest = onDocumentCreated(
  'booking_requests/{requestId}',
  async (event) => {
    const req = event.data?.data();
    if (!req) return;

    const toUid = req.ownerId || req.toUserId || req.receiverId;
    const fromUid = req.requesterId || req.fromUserId || req.senderId;
    if (!toUid || toUid === fromUid) return;

    const [name, tokensByUid] = await Promise.all([
      displayName(fromUid),
      tokensFor([toUid]),
    ]);

    await sendAndPrune(tokensByUid, {
      notification: {
        title: 'New booking request',
        body: `${name} wants to travel with you`,
      },
      data: {
        type: 'booking',
        requestId: event.params.requestId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });
  }
);
