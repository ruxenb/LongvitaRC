#!/usr/bin/env node
'use strict';

/**
 * FCM Dispatcher Daemon for LongvitaRC.
 * Listens to Firestore 'fcm_broadcasts' collection and dispatches
 * real FCM Push Notifications to topics / devices using Firebase Admin SDK.
 */

const fs = require('node:fs');
const path = require('node:path');

const keyCandidates = [
  path.resolve(__dirname, '../firebase/service-account.json'),
  path.resolve(__dirname, '../service-account.json'),
  process.env.GOOGLE_APPLICATION_CREDENTIALS,
].filter(Boolean);

let keyPath = keyCandidates.find(p => fs.existsSync(p));

if (!keyPath) {
  console.error('\n❌ Không tìm thấy file khóa "service-account.json"!');
  console.error('👉 Vui lòng tải file từ Firebase Console > Project Settings > Service accounts > Generate new private key');
  console.error('👉 Đổi tên thành "service-account.json" và lưu vào thư mục "firebase/service-account.json"\n');
  process.exit(1);
}

let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  try {
    admin = require(path.resolve(__dirname, '../firebase/node_modules/firebase-admin'));
  } catch (e2) {
    console.error('\n❌ Chưa cài đặt thư viện "firebase-admin"!');
    console.error('👉 Hãy chạy lệnh trong terminal: npm install firebase-admin --prefix firebase\n');
    process.exit(1);
  }
}

const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

console.log('====================================================');
console.log('🚀 LONGVITA FCM DISPATCHER DAEMON ĐANG HOẠT ĐỘNG');
console.log(`📁 Project: ${serviceAccount.project_id}`);
console.log(`🔑 Service Account: ${serviceAccount.client_email}`);
console.log('📡 Đang lắng nghe hàng đợi "fcm_broadcasts"...');
console.log('====================================================\n');

// Lắng nghe các thông báo đẩy đang chờ gửi (status == "pending")
db.collection('fcm_broadcasts')
  .where('status', '==', 'pending')
  .onSnapshot(
    snapshot => {
      snapshot.docChanges().forEach(async change => {
        if (change.type === 'added') {
          const doc = change.doc;
          const data = doc.data();
          const id = doc.id;

          console.log(`\n📨 [${new Date().toLocaleTimeString()}] Phát hiện yêu cầu gửi Push Notification (ID: ${id})`);
          console.log(`   - Tiêu đề: "${data.title}"`);
          console.log(`   - Nội dung: "${data.body}"`);
          console.log(`   - Chế độ gửi: ${data.targetType}`);

          const baseMessage = {
            notification: {
              title: data.title,
              body: data.body,
            },
            data: {
              message_id: id,
              schema_version: '1',
              target_type: 'announcement',
              target_id: id,
              recipient_uid: data.recipientUid || 'all',
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                defaultSound: true,
                defaultVibrateTimings: true,
              },
            },
          };

          try {
            if (data.token || (data.recipientUid && data.recipientUid.length > 50)) {
              const targetToken = data.token || data.recipientUid;
              console.log(`   -> Đang bắn trực tiếp tới Device Token: "${targetToken.substring(0, 20)}..."`);
              await messaging.send({ ...baseMessage, token: targetToken });
            } else if (data.targetType === 'all') {
              console.log('   -> Đang bắn tới Topic: "all_users"...');
              await messaging.send({ ...baseMessage, topic: 'all_users' });
            } else if (data.targetType === 'role' && Array.isArray(data.targetRoles)) {
              for (const role of data.targetRoles) {
                console.log(`   -> Đang bắn tới Topic: "role_${role}"...`);
                await messaging.send({ ...baseMessage, topic: `role_${role}` });
              }
            } else if (data.targetType === 'user' && data.recipientUid) {
              console.log(`   -> Đang bắn tới Topic cá nhân: "user_${data.recipientUid}"...`);
              await messaging.send({
                ...baseMessage,
                topic: `user_${data.recipientUid}`,
              });
            } else {
              // Mặc định gửi all
              await messaging.send({ ...baseMessage, topic: 'all_users' });
            }

            // Đánh dấu đã gửi thành công
            await doc.ref.update({
              status: 'sent',
              sentAt: new Date().toISOString(),
            });

            console.log(`✅ [THÀNH CÔNG] Đã bắn Push Notification cho "${data.title}"!\n`);
          } catch (err) {
            console.error(`❌ [THẤT BẠI] Lỗi khi gửi FCM:`, err.message);
            await doc.ref.update({
              status: 'failed',
              error: err.message,
              failedAt: new Date().toISOString(),
            });
          }
        }
      });
    },
    error => {
      console.error('❌ Lỗi kết nối Firestore Listener:', error);
    }
  );
