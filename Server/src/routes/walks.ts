import {firebase} from "../firebase/firebase";
import express from "express";
import {Authed} from "../firebase/util";
import {firestore} from "firebase-admin";
import date from 'date-and-time';
import { Response } from "express-serve-static-core";

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string
}

function GetDateFromStr(yyyyMD: string): number {
    return parseInt(date.format(new Date(yyyyMD), 'YYYYMD'))
}

function GetWalksFromTo(res: Response<any, Record<string, any>, number>, from: string, to: string) {
    const start = GetDateFromStr(from);
    const end = GetDateFromStr(to);
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
}

function GetWalksOnDayUser(res: Response<any, Record<string, any>, number>, name: string, day: string) {
    const start = GetDateFromStr(day);
    console.log(name);
    console.log(start);
    firebase.firestore().collection('walks')
        .where('finalwalker', '==', name)
        .where('date', '>=', start)
        .where('date', '<=', start)
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
}

//TODO: figure out a way to clean this mess up
module.exports = function(app: express.Express) {
    // for testing purposes
    app.get("/addtestwalk/:date", (req, res) => {
        const data = {
            date: GetDateFromStr(req.params.date),
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
                    const start = GetDateFromStr(req.params.date);
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

    app.get('/walks/:possiblefrom/:to', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    const test = GetDateFromStr(req.params.possiblefrom);
                    if (test != undefined && test > 0) {
                        console.log('valid');
                        GetWalksFromTo(res, req.params.possiblefrom, req.params.to);
                    } else {
                        console.log('invalid')
                        GetWalksOnDayUser(res, req.params.possiblefrom, req.params.to);
                    }
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
                    const start = GetDateFromStr(req.params.from);
                    const end = GetDateFromStr(req.params.to);
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