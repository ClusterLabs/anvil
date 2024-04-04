import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getAlertOverrideRequestBody } from './getAlertOverrideRequestBody';
import { perr, pout } from '../../shell';

export const createAlertOverride: RequestHandler<
  undefined,
  undefined,
  AlertOverrideRequestBody
> = (request, response) => {
  const { body: rBody = {} } = request;

  pout(`Begin creating alert override.`);

  let body: AlertOverrideRequestBody;

  try {
    body = getAlertOverrideRequestBody(rBody);
  } catch (error) {
    perr(`Failed to process alert override input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('alert-overrides', 'add', { body });
  } catch (error) {
    perr(`Failed to create alert override; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(201).send();
};
