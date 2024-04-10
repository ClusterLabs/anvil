import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { perr } from '../../shell';

export const deleteAlertOverride: RequestHandler<AlertOverrideReqParams> = (
  request,
  response,
) => {
  const {
    params: { uuid },
  } = request;

  try {
    execManageAlerts('alert-overrides', 'delete', { uuid });
  } catch (error) {
    perr(`Failed to delete alert override: CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(204).send();
};
