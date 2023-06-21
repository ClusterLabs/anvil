import { RequestHandler } from 'express';

import { anvilSyncShared } from '../../accessModule';
import { stdout, stdoutVar } from '../../shell';

export const createFile: RequestHandler = async ({ file, body }, response) => {
  stdout('Receiving shared file.');

  if (!file) return response.status(400).send();

  stdoutVar({ body, file });

  await anvilSyncShared('move_incoming', `file=${file.path}`, '0132', '0133');

  response.status(201).send();
};
