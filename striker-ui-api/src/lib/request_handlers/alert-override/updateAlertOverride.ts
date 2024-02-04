import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getAlertOverrideRequestBody } from './getAlertOverrideRequestBody';
import { stderr, stdout } from '../../shell';

export const updateAlertOverride: RequestHandler<
  AlertOverrideReqParams,
  undefined,
  AlertOverrideRequestBody
> = (request, response) => {
  const {
    body: rBody = {},
    params: { uuid },
  } = request;

  stdout('Begin updating alert override.');

  let body: AlertOverrideRequestBody;

  try {
    body = getAlertOverrideRequestBody(rBody, uuid);
  } catch (error) {
    stderr(`Failed to process alert override input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('alert-overrides', 'edit', { body, uuid });
  } catch (error) {
    stderr(`Failed to update alert override; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(200).send();
};
