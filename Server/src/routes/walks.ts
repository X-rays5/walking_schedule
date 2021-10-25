import {firebase} from "../firebase/firebase";
import express from "express";
import {Authed, DocExists} from "../firebase/util";
import {firestore} from "firebase-admin";
import date from 'date-and-time';
import { Response } from "express-serve-static-core";

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string,
    date: string,
    id: string
}

function GetDateFromStr(YYYYMD: string): number {
    return parseInt(date.format(new Date(YYYYMD), 'DMYYYY'))
}

function CheckValidDate(YYYYMD: string): boolean {
    const check = GetDateFromStr(YYYYMD);
    return check != undefined && check > 0;
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
                date: val.data().formatteddate,
                id: val.id
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
                date: val.data().formatteddate,
                id: val.id
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

function GetWalkFromId(res: Response<any, Record<string, any>, number>, doc_id: string) {
    firebase.firestore().collection('walks').doc(doc_id).get().then((doc) => {
        const walk: Walk = {
            walker: doc.data().finalwalker,
            interested: doc.data().interested,
            name: doc.data().name,
            date: doc.data().formatteddate,
            id: doc.id
        }
        res.json(walk);
    }).catch((error) => {
        console.log(error);
        res.status(400);
        res.json({
            success: false,
            error: error
        });
    });
}

function GetWalkFromDate(res: Response<any, Record<string, any>, number>, date: string) {
    const start = GetDateFromStr(date);
    firebase.firestore().collection('walks')
        .where('date', '==', start)
        .get().then((doc) => {
            let walks: Walk[] = [];
            doc.docs.forEach((val) => {
                walks.push({
                    walker: val.data().finalwalker,
                    interested: val.data().interested,
                    name: val.data().name,
                    date: val.data().formatteddate,
                    id: val.id
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
        if (CheckValidDate(req.params.date)) {
            const data = {
                date: GetDateFromStr(req.params.date),
                finalwalker: 'none',
                interested: ['Hans', 'Piet', 'Papzakje'],
                name: 'test walk',
                formatteddate: date.format(new Date(req.params.date), 'D-M-YYYY'),
            }
            firebase.firestore().collection('walks').add(data);
            res.send('');
        } else {
            res.status(400);
            res.json({
                success: false,
                error: {
                    code: 'invalid/date',
                }
            })
        }
    });

    // date are expected as yyyy-MM-DD
    app.get('/walks/:possibleid', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    DocExists('walks', req.params.possibleid).then((exists) => {
                        if (exists) {
                            GetWalkFromId(res, req.params.possibleid);
                        } else {
                            GetWalkFromDate(res, req.params.possibleid);
                        }
                    })
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
                                date: val.data().formatteddate,
                                id: val.id
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