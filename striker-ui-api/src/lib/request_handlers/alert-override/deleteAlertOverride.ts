import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { Responder } from '../../Responder';

export const deleteAlertOverride: RequestHandler<
  AlertOverrideReqParams,
  Express.RhResBody,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = (request, response) => {
  const respond = new Responder(response);

  const { uuid } = response.locals.target;

  try {
    execManageAlerts('alert-overrides', 'delete', { uuid });
  } catch (error) {
    return respond.s500(
      '0ce4d10',
      `Failed to delete alert override: CAUSE: ${error}`,
    );
  }

  return respond.s204();
};
