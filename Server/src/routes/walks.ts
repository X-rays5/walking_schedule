import {firebase} from "../firebase/firebase";
import express from "express";
import {Authed} from "../firebase/util";
import {firestore} from "firebase-admin";
import Timestamp = firestore.Timestamp;

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string
}

//TODO: figure out a way to clean this mess up
module.exports = function(app: express.Express) {
    // for testing purposes
    app.get("/addtestwalk", (req, res) => {
        const data = {
            date: Timestamp.fromDate(new Date('2021-10-22')),
            finalwalker: 'none',
            interested: ['Hans', 'Piet', 'Papzakje'],
            name: 'test walk'
        }
        firebase.firestore().collection('walks').add(data);
        res.send('');
    });

    // date are expected as yyyy-MM-DD
    app.get('/walks/:date', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    const start = Timestamp.fromDate(new Date(req.params.date));
                    firebase.firestore().collection('walks')
                        .where('date', '==', start)
                        .get().then((doc) => {
                        let walks: Walk[] = [];
                        doc.docs.forEach((val) => {
                            walks.push({
                                walker: val.data().finalwalker,
                                interested: val.data().interested,
                                name: val.data().name,
                            })
                        });
                        res.json(walks);
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
            }).catch((error) => {
                console.log(error);
                res.status(400);
                res.json({
                    success: false,
                    error: error
                });
            });
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    });

    app.get('/walks/:name/:date', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    const start = Timestamp.fromDate(new Date(req.params.date));
                    firebase.firestore().collection('walks')
                        .where('walkername', '==', req.params.name)
                        .where('date', '==', start)
                        .get().then((doc) => {
                        let walks: Walk[] = [];
                        doc.docs.forEach((val) => {
                            walks.push({
                                walker: val.data().finalwalker,
                                interested: val.data().interested,
                                name: val.data().name,
                            })
                        });
                        res.json(walks);
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
            }).catch((error) => {
                console.log(error);
                res.status(400);
                res.json({
                    success: false,
                    error: error
                });
            });
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    });

    app.get('/walks/:from/:to', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    const start = new Date(req.params.from);
                    const end = new Date(req.params.to);
                    firebase.firestore().collection('walks')
                        .where('date', '>=', start)
                        .where('date', '<=', end)
                        .get().then((doc) => {
                        let walks: Walk[] = [];
                        doc.docs.forEach((val) => {
                            walks.push({
                                walker: val.data().finalwalker,
                                interested: val.data().interested,
                                name: val.data().name,
                            })
                        });
                        res.json(walks);
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
            }).catch((error) => {
                console.log(error);
                res.status(400);
                res.json({
                    success: false,
                    error: error
                });
            });
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    });

    app.get('/walks/:name/:from/:to', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    const start = Timestamp.fromDate(new Date(req.params.from));
                    const end = Timestamp.fromDate(new Date(req.params.to));
                    firebase.firestore().collection('walks')
                        .where('finalwalker', '==', req.params.name)
                        .where('date', '>=', start)
                        .where('date', '<=', end)
                        .get().then((doc) => {
                        let walks: Walk[] = [];
                        doc.docs.forEach((val) => {
                            walks.push({
                                walker: val.data().finalwalker,
                                interested: val.data().interested,
                                name: val.data().name,
                            })
                        });
                        res.json(walks);
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
            }).catch((error) => {
                console.log(error);
                res.status(400);
                res.json({
                    success: false,
                    error: error
                });
            });
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    });
}