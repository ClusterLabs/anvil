import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailServerRequestBody } from './getMailServerRequestBody';
import { stderr, stdout } from '../../shell';

export const updateMailServer: RequestHandler<
  MailServerParamsDictionary,
  undefined,
  MailServerRequestBody
> = (request, response) => {
  const {
    body: rBody = {},
    params: { uuid },
  } = request;

  stdout('Begin updating mail server.');

  let body: MailServerRequestBody;

  try {
    body = getMailServerRequestBody(rBody, uuid);
  } catch (error) {
    stderr(`Failed to process mail server input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('mail-servers', 'edit', { body, uuid });
  } catch (error) {
    stderr(`Failed to update mail server; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(200).send();
};
