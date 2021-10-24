import * as firebase_admin from 'firebase-admin';
const service_account = require('../../walking-schedule-firebase-adminsdk-gk8zs-f00c265b00.json');
export const firebase = firebase_admin.initializeApp({
    credential: firebase_admin.credential.cert(service_account),
});