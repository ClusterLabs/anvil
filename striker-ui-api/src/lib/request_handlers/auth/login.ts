import { RequestHandler } from 'express';

import { stdout } from '../../shell';

export const login: RequestHandler<unknown, unknown, AuthLoginRequestBody> = (
  request,
  response,
) => {
  const { user } = request;

  if (user) {
    const { name: userName } = user as User;

    stdout(`Successfully authenticated user [${userName}]`);
  }

  response.status(200).send();
};
