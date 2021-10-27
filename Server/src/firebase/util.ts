import {firebase} from "./firebase";

export async function CollectionExists(id: string): Promise<boolean> {
    return await firebase.firestore().collection(id).get().then((collection) => {
        return collection.docs.length > 0; // since a collection can only exists when there is at least 1 doc this works
    })
}

export async function DocExists(collection_id: string, doc_id: string): Promise<boolean> {
    return await firebase.firestore().collection(collection_id).doc(doc_id).get().then((doc) => {
       return doc.exists;
    });
}

export async function IsUserName(name: string): Promise<boolean> {
    return await firebase.firestore().collection('users').where('name', '==', name).limit(1).get().then((doc) => {
       return !doc.empty;
    });
}

export async function IsUserId(id: string): Promise<boolean> {
    return await firebase.firestore().collection('users').doc(id).get().then((doc) => {
        return doc.exists;
    })
}

export async function Authed(uid: string): Promise<boolean> {
    if (uid !== undefined && uid.length > 0) {
        return await IsUserId(uid);
    } else {
        return false;
    }
}

export async function IsAdmin(id: string): Promise<boolean> {
    return await firebase.firestore().collection('users')
        .where('uid', '==', id).limit(1).get().then((doc) => {
        return doc.docs.length > 0 && doc.docs[0].data().role == 'admin'
    })
}

export async function AuthedAdmin(uid: string): Promise<boolean> {
    if (uid !== undefined && uid.length > 0) {
        return await IsAdmin(uid);
    } else {
        return false;
    }
}

export interface User {
    name: string,
    photo: string,
    role: string
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
               code: 'auth/user-not-found',
               message: 'There is no user record corresponding to the provided identifier.',
           };
       }
    });
}

export async function SendNotification(title: String, body: String) {
    const message = {
        data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: 'a title',
            body: 'woah'
        },
        topic: 'all'
    };
    return await firebase.messaging().send(message)
        .then((response) => {
            return response;
        })
}