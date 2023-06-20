import { RequestHandler } from 'express';

import { stdout } from '../../shell';
import { cname } from '../../cname';

export const login: RequestHandler<unknown, unknown, AuthLoginRequestBody> = (
  request,
  response,
) => {
  const { user } = request;

  if (user) {
    const { name: userName } = user;

    stdout(`Successfully authenticated user [${userName}]`);

    response.cookie(cname('user'), user);
  }

  response.status(204).send();
};
