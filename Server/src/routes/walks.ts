import {firebase} from "../firebase/firebase";
import express from "express";
import {
    Authed,
    AuthedAdmin, DATABASE_READABLE_DATE_FORMAT,
    DocExists,
    IsUserName,
    SendNotification
} from "../firebase/util";
import date from 'date-and-time';
import {Response} from 'express';
import {CheckValidDate, GetDateFromStr, ObjectToFCMData, ResponseError, ResponseSuccess} from "../util";

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string,
    date: string,
    id: string
}

async function GetWalksFromTo(res: Response, from: string, to: string) {
    const start = GetDateFromStr(from);
    const end = GetDateFromStr(to);

    const walk_collection = await firebase.firestore().collection('walks')
        .where('date', '>=', start)
        .where('date', '<=', end)
        .get();

    let walks: Walk[] = [];
    walk_collection.docs.forEach((val) => {
        walks.push({
            walker: val.data().finalwalker,
            interested: val.data().interested,
            name: val.data().name,
            date: val.data().formatteddate,
            id: val.id
        })
    });

    ResponseSuccess(res, walks);
}

async function GetWalksOnDayUser(res: Response, name: string, day: string) {
    const start = GetDateFromStr(day);

    const walk_collection = await firebase.firestore().collection('walks')
        .where('finalwalker', '==', name)
        .where('date', '>=', start)
        .where('date', '<=', start)
        .get();

    let walks: Walk[] = [];
    walk_collection.docs.forEach((val) => {
        walks.push({
            walker: val.data().finalwalker,
            interested: val.data().interested,
            name: val.data().name,
            date: val.data().formatteddate,
            id: val.id
        })
    });

    ResponseSuccess(res, walks);
}

async function GetWalkFromId(res: Response, doc_id: string) {
    const doc = await firebase.firestore().collection('walks').doc(doc_id).get();

    const walk: Walk = {
        walker: doc.data()?.finalwalker,
        interested: doc.data()?.interested,
        name: doc.data()?.name,
        date: doc.data()?.formatteddate,
        id: doc.id
    }

    ResponseSuccess(res, walk);
}

async function GetWalkFromDate(res: Response, date: string) {
    const start = GetDateFromStr(date);
    const walks_on_date = await firebase.firestore().collection('walks')
        .where('date', '==', start)
        .get();
    let walks: Walk[] = [];
    walks_on_date.docs.forEach((val) => {
        walks.push({
            walker: val.data().finalwalker,
            interested: val.data().interested,
            name: val.data().name,
            date: val.data().formatteddate,
            id: val.id
        })
    });
    ResponseSuccess(res, walks);
}

async function SetUserInterestedInWalk(res: Response, walk_id: string, user_id: string, interested: boolean) {
    let walk = await firebase.firestore().collection('walks').doc(walk_id).get();
    if (!walk.exists) {
        ResponseError(res, 'Walk does not exist', 404);
        return;
    }



    const user = await firebase.auth().getUser(user_id);

    let interested_obj = walk.data()?.interested;
    // @ts-ignore
    interested_obj[user.displayName] = interested;
    await walk.ref.update({interested: interested_obj});
    walk = await firebase.firestore().collection('walks').doc(walk_id).get();

    await SendNotification('admin', {title: walk.data()?.name, body: `${user.displayName} is now ${interested ? 'interested' : 'not interested'}`, data: walk.data()});
    ResponseSuccess(res, {
        walker: walk.data()?.finalwalker,
        interested: walk.data()?.interested,
        name: walk.data()?.name,
        date: walk.data()?.formatteddate,
        id: walk.id
    });
}

module.exports = function(app: express.Express) {
    // date are expected as yyyy-MM-DD
    app.get('/walks/:possibleid', async (req, res) => {
        try {
            if (!await Authed(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            if (await DocExists('walks', req.params.possibleid)) {
                GetWalkFromId(res, req.params.possibleid);
            } else {
                GetWalkFromDate(res, req.params.possibleid);
            }

        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    });

    app.post('/walks/:date', async (req, res) => {
        try {
            if (!await AuthedAdmin(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            if (!CheckValidDate(req.params.date)) {
                ResponseError(res, "Invalid date", 400);
                return;
            }

            console.log(req.body)
            if (req.body.name === undefined || req.body.name === '') {
                ResponseError(res, "Invalid name", 400);
                return;
            }

            const data = {
                date: GetDateFromStr(req.params.date),
                finalwalker: 'none',
                formatteddate: date.format(new Date(req.params.date), DATABASE_READABLE_DATE_FORMAT),
                interested: {placeholder: false},
                name: req.body.name
            }

            await firebase.firestore().collection('walks').add(data);

            await SendNotification('all', {title: `New Walk on ${data.formatteddate}`, body: data.name, data: ObjectToFCMData(data)});
            ResponseSuccess(res, data);

        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    })

    app.patch('walks/:walk_id/date/:date', async (req, res) => {
        try {
            if (!await AuthedAdmin(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            if (!CheckValidDate(req.params.date)) {
                ResponseError(res, "Invalid date", 400);
                return;
            }

            if (!await DocExists('walks', req.params.walk_id)) {
                ResponseError(res, "Invalid walk", 404);
                return;
            }

            let walk = await firebase.firestore().collection('walks').doc(req.params.walk_id).get();
            if (!walk.exists) {
                ResponseError(res, "Invalid walk", 404);
                return;
            }

            await walk.ref.update({
                date: GetDateFromStr(req.params.date),
                formatteddate: date.format(new Date(req.params.date), DATABASE_READABLE_DATE_FORMAT)
            });

            walk = await firebase.firestore().collection('walks').doc(req.params.walk_id).get()
            ResponseSuccess(res, {
                walker: walk.data()?.finalwalker,
                interested: walk.data()?.interested,
                name: walk.data()?.name,
                date: walk.data()?.formatteddate,
                id: walk.id
            });

        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    });

    app.delete('/walks/:id', async (req, res) => {
        try {
            if (!AuthedAdmin(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            if (!await DocExists('walks', req.params.id)) {
                ResponseError(res, "Invalid walk", 404);
                return;
            }

            const walk_to_delete = await firebase.firestore().collection('walks').doc(req.params.id).get()
            await walk_to_delete.ref.delete();

            ResponseSuccess(res, {
                deleted: true
            });
        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    })

    app.get('/walks/:possiblefrom/:to', async (req, res) => {
        try {
            if (!await Authed(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            const test = GetDateFromStr(req.params.possiblefrom);
            if (test != undefined && test > 0) {
                await GetWalksFromTo(res, req.params.possiblefrom, req.params.to);
            } else {
                await GetWalksOnDayUser(res, req.params.possiblefrom, req.params.to);
            }
        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    });

    app.get('/walks/:name/:from/:to', async (req, res) => {
        try {
            if (!await Authed(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            const start = GetDateFromStr(req.params.from);
            const end = GetDateFromStr(req.params.to);
            const walk_collection = await firebase.firestore().collection('walks')
                .where('finalwalker', '==', req.params.name)
                .where('date', '>=', start)
                .where('date', '<=', end)
                .get();
            let walks: Walk[] = [];
            walk_collection.docs.forEach((val) => {
                walks.push({
                    walker: val.data().finalwalker,
                    interested: val.data().interested,
                    name: val.data().name,
                    date: val.data().formatteddate,
                    id: val.id
                })
            });

            ResponseSuccess(res, walks);
        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    });

    app.patch('/walks/:id/interested/:bool', async (req, res) => {
        try {
            if (!await Authed(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            switch (req.params.bool) {
                case 'true':
                    SetUserInterestedInWalk(res, req.params.id, req.header('X-API-Uid')!, true);
                    break;
                case 'false':
                    SetUserInterestedInWalk(res, req.params.id, req.header('X-API-Uid')!, false);
                    break;
                default:
                    ResponseError(res, "Invalid bool", 400);
                    break;
            }
        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    });

    app.patch('/walks/:walk_id/walker/:name', async (req, res) => {
        try {
            if (!await AuthedAdmin(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            if (!await IsUserName(req.params.name)) {
                ResponseError(res, "Invalid name", 400);
                return;
            }

            let walk = await firebase.firestore().collection('walks').doc(req.params.walk_id).get();
            if (!walk.exists) {
                ResponseError(res, "Invalid walk", 404);
                return;
            }

            await walk.ref.update({finalwalker: req.params.name});
            walk = await firebase.firestore().collection('walks').doc(req.params.walk_id).get();

            await SendNotification('all', {title: walk.data()?.name, body: `${req.params.name} has been set as walker`, data: walk.data()});
            ResponseSuccess(res, {
                walker: walk.data()?.finalwalker,
                interested: walk.data()?.interested,
                name: walk.data()?.name,
                date: walk.data()?.formatteddate,
                id: walk.id
            });
        } catch (error: any) {
            ResponseError(res, error, 500);
        }
    })
}