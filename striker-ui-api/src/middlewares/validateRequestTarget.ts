import { RequestHandler } from 'express';

import { Responder } from '../lib/Responder';
import { requestTargetSchema } from './schemas';

export const validateRequestTarget =
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
      const valid = await requestTargetSchema.validate(request.params);

      // .locals is already an object, but anything nested doesn't exist yet.
      response.locals.target = {
        uuid: valid.uuid,
      };
    } catch (error) {
      return respond.s400(
        '3a7fac7',
        `Invalid request identifier; CAUSE: ${error}`,
      );
    }

    return next();
  };
