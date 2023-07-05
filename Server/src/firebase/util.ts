import {firebase} from "./firebase";
import {messaging} from "firebase-admin";
import TopicMessage = messaging.TopicMessage;

export const DATABASE_READABLE_DATE_FORMAT = 'D-M-YYYY';
export const DATABASE_DATE_FORMAT = 'YYYYMMDD';

export interface User {
    name: string,
    photo: string,
    role: string
}

export async function CollectionExists(id: string): Promise<boolean> {
    return await firebase.firestore().collection(id).get().then((collection) => {
        return collection.docs.length > 0; // since a collection can only exist when there is at least 1 doc this works
    })
}

export async function DocExists(collection_id: string, doc_id: string): Promise<boolean> {
    return await firebase.firestore().collection(collection_id).doc(doc_id).get().then((doc) => {
        return doc.exists;
    });
}

export async function UserExists(uid: string): Promise<boolean> {
    return await firebase.auth().getUser(uid).then((user) => {
        return true;
    }).catch((error) => {
        return false;
    })
}

export async function IsUserName(name: string): Promise<boolean> {
    return await firebase.firestore().collection('users').where('name', '==', name).limit(1).get().then((doc) => {
        return !doc.empty;
    });
}

export async function IsUserId(id: string): Promise<boolean> {
    return await UserExists(id).then((exists) => {
        return exists;
    })
}

export async function Authed(uid: string | undefined): Promise<boolean> {
    if (uid !== undefined && uid.length > 0) {
        return await IsUserId(uid);
    } else {
        return false;
    }
}

export async function IsAdmin(id: string): Promise<boolean> {
    return await UserExists(id).then((exists) => {
        if (exists) {
            return firebase.firestore().collection('users')
                .where('uid', '==', id).limit(1).get().then((doc) => {
                    return doc.docs.length > 0 && doc.docs[0].data().role == 'admin'
                })
        } else {
            return false;
        }
    });
}

export async function AuthedAdmin(uid: string | undefined): Promise<boolean> {
    if (uid !== undefined && uid.length > 0) {
        return await IsAdmin(uid);
    } else {
        return false;
    }
}

export async function GetUser(name: string): Promise<User> {
    const collection = firebase.firestore().collection('users');

    // search for name first since that will be most common
    return await collection.where('name', '==', name).get().then((data) => {
        if (!data.empty) {
            const u = data.docs[0];
            return {
                name: u.data().name,
                photo: u.data().photo,
                role: u.data().role,
            };
        } else {
            throw {
                message: 'There is no user record corresponding to the provided identifier.',
            };
        }
    });
}

interface Notification {
    title: string,
    body?: string,
    image_url?: string,
    data?: {
        [key: string]: string;
    };
}

export async function SendNotification(topic: string, notification: Notification) {
    const notify_payload: TopicMessage = {
        notification: {
            title: notification.title,
            body: notification.body,
            imageUrl: notification.image_url,
        },
        data: notification.data,
        topic,
    };
    
    await firebase.messaging().send(notify_payload).then((response) => {
        console.log('Successfully sent message:', response);
    }).catch((error) => {
        console.error('Error sending message:', error);
    });
}