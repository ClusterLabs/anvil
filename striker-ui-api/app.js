const express = require('express');
const path = require('path');

const API_ROOT_PATH = require('./lib/consts/API_ROOT_PATH');

const echoRoute = require('./routes/echo');

const app = express();

app.use(express.json());

app.use(path.join(API_ROOT_PATH, 'echo'), echoRoute);

module.exports = app;
