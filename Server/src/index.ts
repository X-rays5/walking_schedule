// @ts-ignore

import * as firebase_admin from 'firebase-admin';
const service_account = require('../walking-schedule-firebase-adminsdk-gk8zs-f00c265b00.json');
const firebase = firebase_admin.initializeApp({
    credential: firebase_admin.credential.cert(service_account),
});

import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
const app = express();

app.get("/user/:uid", (req, res) => {
   firebase.auth().getUser(req.params.uid).then((user) => {
       res.json({
           username: user.displayName,
           photo: user.photoURL
       });
       console.log('found user', user.toJSON());
   }).catch((error) => {
       console.log(error);
       res.status(400);
       res.json({
           success: false,
           error: error
       });
   });
});

app.post("/user/:uid", (req, res) => {
    firebase.auth().getUser(req.params.uid).then((user) => {
        const collection = firebase.firestore().collection("users");
        collection.doc(req.params.uid).get().then((value => {
            if (value.exists) {
                res.json({
                    success: true,
                    message: 'user already exists',
                });
            } else {
                const data = {
                    uid: req.params.uid,
                    role: 'user'
                };
                collection.doc(req.params.uid).set(data)
                res.json({
                    success: true,
                    message: 'user created',
                });
            }
        })).catch((error) => {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        });
    }).catch((error) => {
        console.log(error);
        res.status(400);
        res.json({
            success: false,
            error: error
        });
    });
});

interface User {
    username: string;
    photo: string;
}

// TODO: implement page tokens
app.get("/users", (req, res) => {
    let users = new Array<firebase_admin.auth.UserRecord>();
    const listAllUsers = (nextPageToken: string) => {
        // List batch of users, 1000 at a time.
        firebase.auth()
            .listUsers(1000, nextPageToken)
            .then((listUsersResult) => {
                let users = new Array<User>();
                listUsersResult.users.forEach((userRecord) => {
                    users.push({
                        username: userRecord.displayName,
                        photo: userRecord.photoURL,
                    });
                });
                res.json(users);
            })
            .catch((error) => {
                console.log(error);
                res.status(400);
                res.json({
                    success: false,
                    error: error
                });
            });
    };

    // @ts-ignore
    // if no pageToken is specified, the operation will list users from the beginning, ordered by uid.
    listAllUsers();
});

// start the Express server
app.listen(process.env.PORT, () => {
    console.log( `server started at http://localhost:${process.env.PORT}` );
} );
