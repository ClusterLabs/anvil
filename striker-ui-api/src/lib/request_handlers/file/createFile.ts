import { RequestHandler } from 'express';

import { anvilSyncShared } from '../../accessModule';
import { stdout, stdoutVar } from '../../shell';

export const createFile: RequestHandler = async ({ files, body }, response) => {
  stdout('Received shared file(s).');

  if (!files) return response.status(400).send();

  stdoutVar({ body, files });

  for (const file of files) {
    await anvilSyncShared('move_incoming', `file=${file.path}`, '0132', '0133');
  }

  response.status(201).send();
};
