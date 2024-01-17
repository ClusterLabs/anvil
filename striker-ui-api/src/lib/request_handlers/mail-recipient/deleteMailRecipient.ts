import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { stderr } from '../../shell';

export const deleteMailRecipient: RequestHandler<
  MailRecipientParamsDictionary
> = (request, response) => {
  const {
    params: { uuid },
  } = request;

  try {
    execManageAlerts('recipients', 'delete', { uuid });
  } catch (error) {
    stderr(`Failed to delete alert recipient; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(204).send();
};
