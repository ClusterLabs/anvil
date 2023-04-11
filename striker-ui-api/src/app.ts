import cors from 'cors';
import express from 'express';

import routes from './routes';
import { rrouters } from './lib/rrouters';

const app = express();

app.use(express.json());
app.use(cors());

rrouters(app, routes, { key: 'api' });
rrouters(app, routes, { key: 'echo' });

export default app;
