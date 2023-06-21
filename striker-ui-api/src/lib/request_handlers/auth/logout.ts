import { RequestHandler } from 'express';

import { stdout } from '../../shell';

export const logout: RequestHandler = (request, response) => {
  request.session.destroy((error) => {
    let scode = 204;

    if (error) {
      scode = 500;

      stdout(`Failed to destroy session upon logout; CAUSE: ${error}`);
    }

    response.status(scode).send();
  });
};
