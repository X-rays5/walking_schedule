import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
const app = express();
app.use(express.json())

// import all routes
require('./routes/user')(app);
require('./routes/walks')(app);

// start the Express server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log( `server started at http://localhost:${PORT}` );
} );
