const cors = require('cors');
const express = require('express');
const path = require('path');

const API_ROOT_PATH = require('./lib/consts/API_ROOT_PATH');

const echoRouter = require('./routes/echo');
const filesRouter = require('./routes/files');

const app = express();

app.use(express.json());
app.use(cors());

app.use(path.join(API_ROOT_PATH, 'echo'), echoRouter);
app.use(path.join(API_ROOT_PATH, 'files'), filesRouter);

module.exports = app;
