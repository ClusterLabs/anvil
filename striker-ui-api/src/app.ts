import cors from 'cors';
import express from 'express';
import path from 'path';

import API_ROOT_PATH from './lib/consts/API_ROOT_PATH';

import { echoRouter, filesRouter, serversRouter } from './routes';

const app = express();

app.use(express.json());
app.use(cors());

app.use(path.join(API_ROOT_PATH, 'echo'), echoRouter);
app.use(path.join(API_ROOT_PATH, 'files'), filesRouter);
app.use(path.join(API_ROOT_PATH, 'servers'), serversRouter);

export default app;
