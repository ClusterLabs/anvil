import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailRecipientRequestBody } from './getMailRecipientRequestBody';
import { stderr, stdout } from '../../shell';

export const createMailRecipient: RequestHandler<
  undefined,
  undefined,
  MailRecipientRequestBody
> = (request, response) => {
  const { body: rBody = {} } = request;

  stdout('Begin creating alert recipient.');

  let body: MailRecipientRequestBody;

  try {
    body = getMailRecipientRequestBody(rBody);
  } catch (error) {
    stderr(`Failed to process alert recipient input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('recipients', 'add', { body });
  } catch (error) {
    stderr(`Failed to create alert recipient; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(201).send();
};
