import {firebase} from "../firebase/firebase";
import express from "express";

module.exports = function(app: express.Express) {
    // for testing purposes
    app.get("/addtestwalk", (req, res) => {
        const data = {
            date: new Date('2021-10-10'),
            finalwalker: 'none',
            interested: [''],
            name: 'test walk'
        }
        firebase.firestore().collection('walks').add(data);
        res.send('');
    });

    app.get('walks/:year/:month/:day', (req, res) => {

    });
}