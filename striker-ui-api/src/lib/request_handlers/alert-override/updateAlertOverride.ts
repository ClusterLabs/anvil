import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getAlertOverrideRequestBody } from './getAlertOverrideRequestBody';
import { perr, pout } from '../../shell';

export const updateAlertOverride: RequestHandler<
  AlertOverrideReqParams,
  undefined,
  AlertOverrideRequestBody
> = (request, response) => {
  const {
    body: rBody = {},
    params: { uuid },
  } = request;

  pout('Begin updating alert override.');

  let body: AlertOverrideRequestBody;

  try {
    body = getAlertOverrideRequestBody(rBody, uuid);
  } catch (error) {
    perr(`Failed to process alert override input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('alert-overrides', 'edit', { body, uuid });
  } catch (error) {
    perr(`Failed to update alert override; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(200).send();
};
