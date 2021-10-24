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