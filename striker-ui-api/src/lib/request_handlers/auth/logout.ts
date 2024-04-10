import { RequestHandler } from 'express';

import { cname } from '../../cname';
import { pout } from '../../shell';

export const logout: RequestHandler = (request, response) => {
  request.session.destroy((error) => {
    if (error) {
      pout(`Failed to destroy session upon logout; CAUSE: ${error}`);

      return response.status(500).send();
    }

    response.clearCookie(cname('session'));
    response.clearCookie(cname('sid'));

    return response.status(204).send();
  });
};
