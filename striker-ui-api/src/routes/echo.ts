import express from 'express';

import { poutvar } from '../lib/shell';

const router = express.Router();

router
  .get('/', (request, response) => {
    response.status(200).send({ message: 'Empty echo.' });
  })
  .post('/', (request, response) => {
    const { body = {} } = request;

    poutvar(body, 'echo:post\n');

    const { message = 'No message.' } = body;

    response.status(200).send({ message });
  });

export default router;
