import { RequestHandler } from 'express';

import { Responder } from '../lib/Responder';
import { requestTargetIdSchema } from './schemas';

export const validateRequestTargetId =
  <
    P extends RequestTarget,
    ResBody = Express.RhResBody,
    ReqBody = Express.RhReqBody,
    ReqQuery = Express.RhReqQuery,
    Locals extends LocalsRequestTarget = LocalsRequestTarget,
  >(): RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals> =>
  async (request, response, next) => {
    const respond = new Responder<ResBody, Locals>(response);

    try {
      const valid = await requestTargetIdSchema.validate(request.params);

      response.locals.target.uuid = valid.uuid;
    } catch (error) {
      return respond.s400(
        '3a7fac7',
        `Invalid request identifier; CAUSE: ${error}`,
      );
    }

    return next();
  };
