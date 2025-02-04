import { RequestHandler } from 'express';

import { OS_LIST_MAP } from '../../consts';

import { Responder } from '../../Responder';

export const lsos: RequestHandler<undefined, ServerOses> = async (
  request,
  response,
) => {
  const respond = new Responder(response);

  return respond.s200(OS_LIST_MAP);
};
