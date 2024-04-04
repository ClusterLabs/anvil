import { Handler } from 'express';

import { pout } from '../lib/shell';

type HandlerParameters = Parameters<Handler>;

type AssertAuthenticationFailFunction = (
  returnTo?: string,
  ...args: HandlerParameters
) => void;

type AssertAuthenticationSucceedFunction = (...args: HandlerParameters) => void;

type AssertAuthenticationOptions = {
  fail?: string | AssertAuthenticationFailFunction;
  failReturnTo?: boolean | string;
  succeed?: string | AssertAuthenticationSucceedFunction;
};

type AssertAuthenticationFunction = (
  options?: AssertAuthenticationOptions,
) => Handler;

export const assertAuthentication: AssertAuthenticationFunction = ({
  fail: initFail = (rt, rq, response) => response.status(404).send(),
  failReturnTo,
  succeed: initSucceed = (request, response, next) => next(),
}: AssertAuthenticationOptions = {}) => {
  let getReturnTo: ((...args: HandlerParameters) => string) | undefined;

  if (failReturnTo === true) {
    getReturnTo = ({ originalUrl, url }) => originalUrl || url;
  } else if (typeof failReturnTo === 'string') {
    getReturnTo = () => failReturnTo;
  }

  const fail: AssertAuthenticationFailFunction =
    typeof initFail === 'string'
      ? (returnTo, rq, response) =>
          response.redirect(returnTo ? `${initFail}?rt=${returnTo}` : initFail)
      : initFail;

  const succeed: AssertAuthenticationSucceedFunction =
    typeof initSucceed === 'string'
      ? (request, response) => response.redirect(initSucceed)
      : initSucceed;

  return (...args) => {
    const { 0: request } = args;
    const { originalUrl, session } = request;
    const { passport } = session;

    if (passport?.user) return succeed(...args);

    const rt = getReturnTo?.call(null, ...args);

    pout(`Unauthenticated access to ${originalUrl}`);

    if (rt) {
      pout(`Set session.returnTo=${rt}`);

      session.returnTo = rt;
    }

    return fail(rt, ...args);
  };
};

export const guardApi = assertAuthentication();
