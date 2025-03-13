import { RequestHandler } from 'express';

import { Responder } from '../lib/Responder';
import { requestTargetIdSchema } from './schemas';

export const validateRequestTargetId = async <
  P extends { uuid: string },
  ResBody = Express.RhResBody,
  ReqBody = Express.RhReqBody,
  ReqQuery = Express.RhReqQuery,
  Locals extends Express.RhLocals = Express.RhLocals,
>(
  ...[request, response, next]: Parameters<
    RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals>
  >
) => {
  const respond = new Responder<ResBody, Locals>(response);

  try {
    await requestTargetIdSchema.validate(request.params);
  } catch (error) {
    return respond.s400(
      '3a7fac7',
      `Invalid request identifier; CAUSE: ${error}`,
    );
  }

  return next();
};
