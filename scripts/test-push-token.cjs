#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const admin = require(path.resolve(__dirname, '../firebase/node_modules/firebase-admin'));

const serviceAccount = JSON.parse(
  fs.readFileSync(path.resolve(__dirname, '../firebase/service-account.json'), 'utf8')
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const messaging = admin.messaging();
const token = process.argv[2] || process.env.FCM_DEVICE_TOKEN || 'cFuFdUGPQBmUbfN1lvkW1x:APA91bHNz4BAwGGu0OxQ82LhzRPMB1alsTOKz7hakG-6Dkq5w-uUMHPdgGA-vILz15B0i_FdsG8FbiyzRJekiyipN8Fj0tKNtC4seLphJK1EQuBAVyKR0Pc';

async function sendDirectPush() {
  console.log('🚀 Đang gửi Push Notification trực tiếp đến token thiết bị...');
  console.log('📱 Token:', token.substring(0, 30) + '...');

  const message = {
    token: token,
    notification: {
      title: 'Longvita Push Thành Công! 🎉',
      body: 'Thông báo đẩy đã đến điện thoại của bạn rồi!',
    },
    data: {
      message_id: 'test_token_' + Date.now(),
      schema_version: '1',
      target_type: 'announcement',
      target_id: 'test',
      recipient_uid: 'all',
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
    const response = await messaging.send(message);
    console.log('✅ [THÀNH CÔNG RỰC RỠ] Đã gửi tới thiết bị! Message ID:', response);
  } catch (error) {
    console.error('❌ Lỗi khi gửi:', error);
  }
}

sendDirectPush().then(() => process.exit(0));
