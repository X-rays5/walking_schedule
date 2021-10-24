import {firebase} from "../firebase/firebase";
import express from "express";

interface User {
    username: string;
    photo: string;
}

module.exports = function(app: express.Express) {
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
                    collection.doc(req.params.uid).set(data);
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

    // TODO: implement page tokens
    app.get("/users", (req, res) => {
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
}