import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailRecipientRequestBody } from './getMailRecipientRequestBody';
import { stderr, stdout } from '../../shell';

export const updateMailRecipient: RequestHandler<
  MailRecipientParamsDictionary,
  undefined,
  MailRecipientRequestBody
> = (request, response) => {
  const {
    body: rBody = {},
    params: { uuid },
  } = request;

  stdout('Begin updating mail recipient.');

  let body: MailRecipientRequestBody;

  try {
    body = getMailRecipientRequestBody(rBody, uuid);
  } catch (error) {
    stderr(`Failed to process mail recipient input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    execManageAlerts('recipients', 'edit', { body, uuid });
  } catch (error) {
    stderr(`Failed to update mail recipient; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(200).send();
};
