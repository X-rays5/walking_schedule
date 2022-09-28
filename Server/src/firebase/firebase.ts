import * as firebase_admin from 'firebase-admin';
// @ts-ignore
const service_account = JSON.parse(process.env.FIREBASE_CREDENTIAL);
export const firebase = firebase_admin.initializeApp({
    credential: firebase_admin.credential.cert(service_account),
});