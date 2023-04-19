import { Handler, Request, Response } from 'express';

import { stdout } from './shell';

export const assertAuthentication: (options?: {
  failureRedirect?: string;
  failureReturnTo?: boolean | string;
}) => Handler = ({ failureRedirect, failureReturnTo } = {}) => {
  const redirectOnFailure: (response: Response) => void = failureRedirect
    ? (response) => response.redirect(failureRedirect)
    : (response) => response.status(404).send();

  let getSessionReturnTo: ((request: Request) => string) | undefined;

  if (failureReturnTo === true) {
    getSessionReturnTo = ({ originalUrl, url }) => originalUrl || url;
  } else if (typeof failureReturnTo === 'string') {
    getSessionReturnTo = () => failureReturnTo;
  }

  return (request, response, next) => {
    const { originalUrl, session } = request;
    const { passport } = session;

    if (!passport?.user) {
      session.returnTo = getSessionReturnTo?.call(null, request);

      stdout(
        `Unauthenticated access to ${originalUrl}; set return to ${session.returnTo}`,
      );

      return redirectOnFailure?.call(null, response);
    }

    next();
  };
};

export const authenticationHandler = assertAuthentication();
