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
import {Request, Response} from 'express';
import {SendQueuedNotification} from "./firebase/util";
import {ResponseError, ResponseSuccess} from "./util";
const app = express();

const REQUEST_LOGGER = (req: Request, res: Response, next: () => void) => {
    console.log(`Receiving request from ${req.ip} to ${req.url}`);
    next();
};

app.use(express.json())
app.use(REQUEST_LOGGER);
app.set('trust proxy', true);

// import all routes
require('./routes/user')(app);
require('./routes/walks')(app);

// endpoint to check if api up
app.get('/', (req, res) => {
    ResponseSuccess(res, {'status': 'up'});
})

app.all('*', (req, res) => {
    console.log(`Sending 404 to ${req.ip} to ${req.url}`);
    ResponseError(res, 'Invalid URL', 404);
});

const port = process.env.PORT || 8080
app.listen(port, () => {
  console.log("Running on port ", port);
});

module.exports = app;

setInterval(() => {
    SendQueuedNotification();
}, 5000);