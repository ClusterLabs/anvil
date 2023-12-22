import { RequestHandler } from 'express';

import { stdout } from '../../shell';
import { cname } from '../../cname';

export const login: RequestHandler<unknown, unknown, AuthLoginRequestBody> = (
  request,
  response,
) => {
  const { session, user } = request;

  if (user) {
    const { name: userName } = user;

    stdout(`Successfully authenticated user [${userName}]`);

    response.cookie(cname('session'), {
      expires: session?.cookie?.expires,
      user,
    });
  }

  response.status(204).send();
};
