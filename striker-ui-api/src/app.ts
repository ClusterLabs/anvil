import cors from 'cors';
import express from 'express';
import path from 'path';

import API_ROOT_PATH from './lib/consts/API_ROOT_PATH';

import echoRouter from './routes/echo';
import filesRouter from './routes/files';

const app = express();

app.use(express.json());
app.use(cors());

app.use(path.join(API_ROOT_PATH, 'echo'), echoRouter);
app.use(path.join(API_ROOT_PATH, 'files'), filesRouter);

export default app;
