import {firebase} from "../firebase/firebase";
import * as firebase_t from 'firebase-admin';
import express from "express";
import {Authed, AuthedAdmin, DocExists, IsUserName, SendNotification} from "../firebase/util";
import date from 'date-and-time';
import { Response } from "express-serve-static-core";

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string,
    date: string,
    id: string
}

function GetDateFromStr(YYYYMMDD: string): number {
    return parseInt(date.format(new Date(YYYYMMDD), 'YYYYMMDD'))
}

function CheckValidDate(YYYYMMDD: string): boolean {
    const check = GetDateFromStr(YYYYMMDD);
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

function SetUserInterestedInWalk(res: Response<any, Record<string, any>, number>, walk_id: string, user_id: string, interested: boolean) {
    firebase.firestore().collection('walks').doc(walk_id).get().then((walk) => {
        if (walk.exists) {
            firebase.auth().getUser(user_id).then((user) => {
                let interestedobj = walk.data().interested;
                // @ts-ignore
                interestedobj[user.displayName] = interested;
                walk.ref.update({
                    interested: interestedobj
                }).then((doc) => {
                    firebase.firestore().collection('walks').doc(walk_id).get().then((updated_walk) => {
                        res.json({
                            walker: updated_walk.data().finalwalker,
                            interested: updated_walk.data().interested,
                            name: updated_walk.data().name,
                            date: updated_walk.data().formatteddate,
                            id: updated_walk.id
                        });
                    })
                }).catch((error) => {
                    console.log(error);
                    res.status(500);
                    res.json({
                        success: false,
                        error: error
                    });
                });
                SendNotification(walk.data().name, `${user.displayName} is now ${interested ? 'interested' : 'not interested'}`, 'admin', walk.data());
            }).catch((error) => {
                console.log(error);
                res.status(400);
                res.json({
                    success: false,
                    error: error
                });
            })
        } else {
            res.status(404);
            res.json({
                success: false,
                error: {
                    code: 'invalid/not-found'
                }
            });
        }
    }).catch((error) => {
        console.log(error);
        res.status(400);
        res.json({
            success: false,
            error: error
        });
    });
}

module.exports = function(app: express.Express) {
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

    app.post('/walks/:date', (req, res) => {
        try {
            AuthedAdmin(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    firebase.firestore().collection('users').doc()
                    if (CheckValidDate(req.params.date)) {
                        if (req.body.name !== undefined) {
                            const data = {
                                date: GetDateFromStr(req.params.date),
                                finalwalker: 'none',
                                formatteddate: date.format(new Date(req.params.date), 'D-M-YYYY'),
                                interested: {placeholder: false},
                                name: req.body.name
                            }
                            firebase.firestore().collection('walks').add(data);
                            res.json({
                                walker: data.finalwalker,
                                interested: data.interested,
                                name: data.name,
                                date: data.formatteddate,
                            });
                            SendNotification(`New Walk on ${data.formatteddate}`, data.name, 'all', data);
                        } else {
                            res.status(400);
                            res.json({
                                success: false,
                                error: {
                                    code: 'missing/name'
                                }
                            })
                        }
                    } else {
                        res.status(400);
                        res.json({
                            success: false,
                            error: {
                                code: 'invalid/date'
                            }
                        })
                    }
                } else {
                    res.status(403);
                    res.send();
                }
            });
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    })

    app.delete('/walks/:id', (req, res) => {
        try {
            AuthedAdmin(req.header('X-API-Uid')).then((authed) => {
               if (authed) {
                   DocExists('walks', req.params.id).then((exists) => {
                       if (exists) {
                           firebase.firestore().collection('walks').doc(req.params.id).get().then((doc) => {
                              doc.ref.delete();
                              res.json({
                                  success: true
                              });
                           });
                       } else {
                           res.status(404);
                           res.json({
                               success: false,
                               error: {
                                   code: 'invalid/walk-id'
                               }
                           })
                       }
                   })
               } else {
                   res.status(403);
                   res.send();
               }
            });
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    })

    app.get('/walks/:possiblefrom/:to', (req, res) => {
        try {
            Authed(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    const test = GetDateFromStr(req.params.possiblefrom);
                    if (test != undefined && test > 0) {
                        GetWalksFromTo(res, req.params.possiblefrom, req.params.to);
                    } else {
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

    app.patch('/walks/:id/interested/:bool', (req, res) => {
       try {
           Authed(req.header('X-API-Uid')).then((authed) => {
               if (authed) {
                   switch (req.params.bool) {
                       case 'true':
                           SetUserInterestedInWalk(res, req.params.id, req.header('X-API-Uid'), true);
                           break;
                       case 'false':
                           SetUserInterestedInWalk(res, req.params.id, req.header('X-API-Uid'), false);
                           break;
                       default:
                           res.status(400);
                           res.json({
                               success: false,
                               error: {
                                   code: 'invalid/bool'
                               }
                           });
                           break;
                   }
               } else  {
                   res.status(403);
                   res.send();
               }
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

    app.patch('/walks/:walk_id/walker/:name', (req, res) => {
        try {
            AuthedAdmin(req.header('X-API-Uid')).then((authed) => {
                if (authed) {
                    IsUserName(req.params.name).then((exists) => {
                        if (exists) {
                            firebase.firestore().collection('walks').doc(req.params.walk_id).get().then((walk) => {
                                if (walk.exists) {
                                    walk.ref.update({
                                        finalwalker: req.params.name
                                    }).then((doc) => {
                                        firebase.firestore().collection('walks').doc(req.params.walk_id).get().then((updated_walk) => {
                                            res.json({
                                                walker: updated_walk.data().finalwalker,
                                                interested: updated_walk.data().interested,
                                                name: updated_walk.data().name,
                                                date: updated_walk.data().formatteddate,
                                                id: updated_walk.id
                                            });
                                        })
                                    }).catch((error) => {
                                        console.log(error);
                                        res.status(400);
                                        res.json({
                                            success: false,
                                            error: error
                                        });
                                    })
                                    SendNotification(walk.data().name, `${req.params.name} has been set as walker`, 'all', walk.data());
                                } else {
                                    res.status(404);
                                    res.json({
                                        success: false,
                                        error: {
                                            code: 'invalid/not-found'
                                        }
                                    });
                                }
                            })
                        } else {
                            res.status(400);
                            res.json({
                                success: false,
                                error: {
                                    code: 'invalid/user'
                                }
                            });
                        }
                    });
                } else {
                    res.status(403);
                    res.send();
                }
            })
        } catch (error) {
            console.log(error);
            res.status(400);
            res.json({
                success: false,
                error: error
            });
        }
    })
}