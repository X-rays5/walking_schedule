import {firebase} from "../firebase/firebase";
import {Authed, GetUser, User, DATABASE_DATE_FORMAT} from "../firebase/util";
import express from "express";
import date from 'date-and-time';
import {ResponseError, ResponseSuccess} from "../util";

interface Walk {
    walker: string,
    interested: Array<string>,
    name: string
}

module.exports = function(app: express.Express) {
    app.get("/user/:name", async (req, res) => {
        try {
            if (!await Authed(req.header("X-API-Uid"))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            const user = await GetUser(req.params.name);
            const cur_date = new Date();
            const year = cur_date.getFullYear();
            const month = cur_date.getMonth();
            const start_date = parseInt(date.format(new Date(year, month, 1), DATABASE_DATE_FORMAT));
            const end_date = parseInt(date.format(new Date(year, month + 1, 0), DATABASE_DATE_FORMAT));

            const this_month_walks = await firebase.firestore().collection('walks')
                .where('finalwalker', '==', user.name)
                .where('date', '>=', start_date)
                .where('date', '<=', end_date)
                .get();

            let walks: Walk[] = [];
            this_month_walks.docs.forEach((val) => {
                walks.push({
                    walker: val.data().finalwalker,
                    interested: val.data().interested,
                    name: val.data().name,
                })
            });

            ResponseSuccess(res, {
                username: user.name,
                photo: user.photo,
                role: user.role,
                walks_this_month: walks
            });
        } catch (e: any) {
            ResponseError(res, e.message, 500);
        }
    });

    // this endpoint is called on every login of a user, so we can use this to access user data
    // and then store it for later use
    app.post("/user/:uid", async (req, res) => {
        try {
            const user = await firebase.auth().getUser(req.params.uid);
            const user_collection = firebase.firestore().collection("users")
            const user_doc = await user_collection.doc(req.params.uid).get();

            if (user_doc.exists) {
                ResponseSuccess(res, {
                    username: user_doc.data()?.name,
                    photo: user_doc.data()?.photo,
                    role: user_doc.data()?.role,
                });
            } else {
                const data = {
                    name: user.displayName,
                    photo: user.photoURL,
                    uid: user.uid,
                    role: 'user'
                };
                await user_collection.doc(user.uid).set(data)
                ResponseSuccess(res, data);
            }
        } catch (e: any) {
            ResponseError(res, e.message, 500);
        }
    });

    app.get("/users/:page", async (req, res) => {
        try {
            if (!await Authed(req.header('X-API-Uid'))) {
                ResponseError(res, "Not authorized", 401);
                return;
            }

            const collection = firebase.firestore().collection('users');
            const users_collection = await collection.limit(100).get();

            let users: User[] = [];
            users_collection.docs.forEach((val) => {
                users.push({
                    name: val.data().name,
                    photo: val.data().photo,
                    role: val.data().role
                });
            });

            ResponseSuccess(res, users);
        } catch (e: any) {
            ResponseError(res, e.message, 500);
        }
    });
}