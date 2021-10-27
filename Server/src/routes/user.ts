import {firebase} from "../firebase/firebase";
import {Authed, DocExists, GetUser, IsUserId, SendNotification, User} from "../firebase/util";
import express from "express";
import {firestore} from "firebase-admin";
import date from 'date-and-time';

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string
}

module.exports = function(app: express.Express) {
    app.get('/notify', (req, res) => {
        SendNotification('test', 'woah').then((result) => {
           res.send(result);
        }).catch((error) => {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        })
    });

    app.get("/user/:name", (req, res) => {
        Authed(req.header('X-API-Uid')).then((authed) => {
            if (authed) {
                GetUser(req.params.name).then((user) => {
                    // get start and end date of current month
                    const cur_date = new Date(), y = cur_date.getFullYear(), m = cur_date.getMonth();
                    const start_date = parseInt(date.format(new Date(y, m, 1), 'DMYYYY'));
                    const end_date = parseInt(date.format(new Date(y, m + 1, 0), 'DMYYYY'));

                    firebase.firestore().collection('walks')
                        .where('finalwalker', '==', user.name)
                        .where('date', '>=', start_date)
                        .where('date', '<=', end_date)
                        .get().then((doc) => {
                        let walks: Walk[] = [];
                        doc.docs.forEach((val) => {
                            walks.push({
                                walker: val.data().finalwalker,
                                interested: val.data().interested,
                                name: val.data().name,
                            })
                        });
                        res.json({
                            username: user.name,
                            photo: user.photo,
                            role: user.role,
                            walks_this_month: walks
                        });
                    }).catch((error) => {
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
            } else {
                res.status(403);
                res.send();
            }
        });
    });

    // this endpoint is called on every login of a user so we can use this to access user data
    // and then store it for later use
    app.post("/user/:uid", (req, res) => {
        firebase.auth().getUser(req.params.uid).then((user) => {
            const collection = firebase.firestore().collection("users");
            collection.doc(user.uid).get().then((value => {
                if (value.exists) {
                    res.json({
                        success: true,
                        message: 'user already exists',
                    });
                } else {
                    const data = {
                        name: user.displayName,
                        photo: user.photoURL,
                        uid: user.uid,
                        role: 'user'
                    };
                    collection.doc(user.uid).set(data)
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

    app.get("/users/:page", (req, res) => {
        Authed(req.header('X-API-Uid')).then((authed) => {
            if (authed) {
                const collection = firebase.firestore().collection('users');
                collection.limit(100).get().then((doc) => {
                    let users: User[] = [];
                    doc.docs.forEach((val) => {
                        users.push({
                            name: val.data().name,
                            photo: val.data().photo,
                            role: val.data().role
                        });
                    });
                    users.pop(); // if we don't pop it sends a random empty member for some reason
                    res.json(users);
                }).catch((error) => {
                    console.log(error);
                    res.status(500);
                    res.json({
                        success: false,
                        error: error
                    });
                });
            } else {
                res.status(403);
                res.send('');
            }
        }).catch((error) => {
            console.log(error);
            res.status(500);
            res.json({
                success: false,
                error: error
            });
        });
    });
}