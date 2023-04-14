import { RequestHandler } from 'express';

import { stdout } from '../../shell';

export const login: RequestHandler<unknown, unknown, AuthLoginRequestBody> = (
  request,
  response,
) => {
  stdout(`session=${JSON.stringify(request.session, null, 2)}`);
  stdout(`user=${JSON.stringify(request.user, null, 2)}`);

  response.status(200).send();
};
