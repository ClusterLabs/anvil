import cors from 'cors';
import express from 'express';
import path from 'path';

import API_ROOT_PATH from './lib/consts/API_ROOT_PATH';

import routes from './routes';

const app = express();

app.use(express.json());
app.use(cors());

Object.entries(routes).forEach(([route, router]) => {
  app.use(path.join(API_ROOT_PATH, route), router);
});

export default app;
