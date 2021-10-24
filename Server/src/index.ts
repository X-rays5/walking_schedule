import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
const app = express();

// import all routes
require('./routes/user')(app);
require('./routes/walks')(app);

// start the Express server
app.listen(process.env.PORT, () => {
    console.log( `server started at http://localhost:${process.env.PORT}` );
} );
