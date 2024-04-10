import { RequestHandler } from 'express';

import { anvilSyncShared } from '../../accessModule';
import { pout, poutvar } from '../../shell';

export const createFile: RequestHandler = async ({ files, body }, response) => {
  pout('Received shared file(s).');

  if (!files) return response.status(400).send();

  poutvar({ body, files });

  for (const file of files) {
    await anvilSyncShared('move_incoming', `file=${file.path}`, '0132', '0133');
  }

  response.status(201).send();
};
