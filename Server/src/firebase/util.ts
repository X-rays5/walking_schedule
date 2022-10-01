import {firebase} from "./firebase";

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
    data: any,
    topic: string
}

const TIME_BETWEEN_NOTIFICATIONS = 10000;
let last_notification_for_topic: Map<string, number> = new Map<string, number>();
let notification_queue: Array<Notification> = [];
function QueueNotification(data: any, topic: string) {
    let last_notification = last_notification_for_topic.get(topic)! | 0;
    if (last_notification < Date.now() + TIME_BETWEEN_NOTIFICATIONS) {
        SendNotificationImpl({data, topic});
    } else {
        notification_queue.push({data, topic});
    }
}

export function SendQueuedNotification() {
    if (notification_queue.length > 0) {
        console.log('Sending a queued notification');
        SendNotificationImpl(notification_queue.shift()!);
    }
}

function SendNotificationImpl(notification: Notification) {
    let last_notification = last_notification_for_topic.get(notification.topic)! | 0;
    if (last_notification < Date.now() + TIME_BETWEEN_NOTIFICATIONS) {
        last_notification_for_topic.set(notification.topic, Date.now());

        const message = {
            data: notification.data,
            topic: notification.topic
        };
        firebase.messaging().send(message).then((response) => {
            console.log('Successfully sent message:', response);
        }).catch((error) => {
            console.log('Error sending message:', error);
        });
    }
}

export async function SendNotification(title: string, body: string, topic: string, data?: any) {
    if (data === undefined) {
        data = {};
    } else {
        for (const key in data) {
            if (key === 'title' || key === 'body' || key === 'topic') {
                throw {
                    message: 'Data cannot contain "title", "body" or "topic" keys.'
                }
            }

            if (data.hasOwnProperty(key)) {
                const element = data[key];
                if (typeof element === 'string') {
                    data[key] = element;
                } else if (typeof element === 'number') {
                    data[key] = element.toString();
                } else if (element instanceof Date) {
                    data[key] = element.toISOString();
                } else {
                    delete data[key];
                }
            }
        }
    }

    data.title = title;
    data.body = body;
    QueueNotification(data, topic);
}