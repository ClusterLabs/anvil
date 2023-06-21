import { Handler } from 'express';

import { stdout } from './shell';

type AssertAuthenticationOptions = {
  fail?: string | ((...args: Parameters<Handler>) => void);
  failReturnTo?: boolean | string;
  succeed?: string | ((...args: Parameters<Handler>) => void);
};

type AssertAuthenticationFunction = (
  options?: AssertAuthenticationOptions,
) => Handler;

export const assertAuthentication: AssertAuthenticationFunction = ({
  fail: initFail = (request, response) => response.status(404).send(),
  failReturnTo,
  succeed: initSucceed = (request, response, next) => next(),
}: AssertAuthenticationOptions = {}) => {
  const fail: (...args: Parameters<Handler>) => void =
    typeof initFail === 'string'
      ? (request, response) => response.redirect(initFail)
      : initFail;

  const succeed: (...args: Parameters<Handler>) => void =
    typeof initSucceed === 'string'
      ? (request, response) => response.redirect(initSucceed)
      : initSucceed;

  let getReturnTo: ((...args: Parameters<Handler>) => string) | undefined;

  if (failReturnTo === true) {
    getReturnTo = ({ originalUrl, url }) => originalUrl || url;
  } else if (typeof failReturnTo === 'string') {
    getReturnTo = () => failReturnTo;
  }

  return (...args) => {
    const { 0: request } = args;
    const { originalUrl, session } = request;
    const { passport } = session;

    if (passport?.user) return succeed(...args);

    session.returnTo = getReturnTo?.call(null, ...args);

    stdout(
      `Unauthenticated access to ${originalUrl}; set return to ${session.returnTo}`,
    );

    return fail(...args);
  };
};

export const guardApi = assertAuthentication();
