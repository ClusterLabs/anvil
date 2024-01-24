import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailRecipientRequestBody } from './getMailRecipientRequestBody';
import { stderr, stdout } from '../../shell';

export const createMailRecipient: RequestHandler<
  undefined,
  MailRecipientResponseBody | undefined,
  MailRecipientRequestBody
> = (request, response) => {
  const { body: rBody = {} } = request;

  stdout('Begin creating alert recipient.');

  let reqBody: MailRecipientRequestBody;

  try {
    reqBody = getMailRecipientRequestBody(rBody);
  } catch (error) {
    stderr(`Failed to process alert recipient input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let resBody: MailRecipientResponseBody | undefined;

  try {
    const { uuid = '' } = execManageAlerts('recipients', 'add', {
      body: reqBody,
    });

    resBody = { uuid };
  } catch (error) {
    stderr(`Failed to create alert recipient; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(201).send(resBody);
};
