import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getAlertOverrideRequestBody } from './getAlertOverrideRequestBody';
import { Responder } from '../../Responder';
import { pout } from '../../shell';

export const updateAlertOverride: RequestHandler<
  AlertOverrideReqParams,
  Express.RhResBody,
  AlertOverrideRequestBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = (request, response) => {
  const respond = new Responder(response);

  const { body: rBody = {} } = request;

  const { uuid } = response.locals.target;

  pout('Begin updating alert override.');

  let body: AlertOverrideRequestBody;

  try {
    body = getAlertOverrideRequestBody(rBody, uuid);
  } catch (error) {
    return respond.s400(
      'a397b14',
      `Failed to process alert override input; CAUSE: ${error}`,
    );
  }

  try {
    execManageAlerts('alert-overrides', 'edit', { body, uuid });
  } catch (error) {
    return respond.s500(
      '4cb8ae9',
      `Failed to update alert override; CAUSE: ${error}`,
    );
  }

  return respond.s200();
};
