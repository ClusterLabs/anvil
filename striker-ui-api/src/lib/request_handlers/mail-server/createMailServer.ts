import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailServerRequestBody } from './getMailServerRequestBody';
import { perr, pout } from '../../shell';

export const createMailServer: RequestHandler<
  undefined,
  undefined,
  MailServerRequestBody
> = (request, response) => {
  const { body: rBody = {} } = request;

  pout('Begin creating mail server.');

  let body: MailServerRequestBody;

  try {
    body = getMailServerRequestBody(rBody);
  } catch (error) {
    perr(`Failed to process mail server input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('mail-servers', 'add', { body });
  } catch (error) {
    perr(`Failed to create mail server; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(201).send();
};
