import dotenv from 'dotenv';
dotenv.config();

import {firebase} from "./firebase/firebase";

// if this is set all legacy data will be updated
if (process.env.FIXLEGACY === 'true') {
    console.log('Fixing legacy interested array');
    firebase.firestore().collection('walks').get().then((docs) => {
        docs.forEach((doc) => {
            let interested = doc.data().interested;
            if (Array.isArray(interested)) {
                interested = Object.fromEntries(
                    interested.map((element) => {
                        if (element === '') {
                            return ['placeholder', true];
                        } else {
                            return [element, true];
                        }
                    })
                );
                doc.ref.update({
                    interested: interested
                }).then(r => {console.log('Fixed legacy interested array');}).catch((err) => {console.error(err);});
            }
        })
    })
}

import express from 'express';
const app = express();
app.use(express.json())

// import all routes
require('./routes/user')(app);
require('./routes/walks')(app);

// endpoint to check if api up
app.get('/', (req, res) => {
    res.json({'status': 'up'});
})

// start the Express server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log( `server started at http://localhost:${PORT}` );
});

module.exports = app;
