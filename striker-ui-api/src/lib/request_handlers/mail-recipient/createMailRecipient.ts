import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailRecipientRequestBody } from './getMailRecipientRequestBody';
import { perr, pout } from '../../shell';

export const createMailRecipient: RequestHandler<
  undefined,
  MailRecipientResponseBody | undefined,
  MailRecipientRequestBody
> = (request, response) => {
  const { body: rBody = {} } = request;

  pout('Begin creating mail recipient.');

  let reqBody: MailRecipientRequestBody;

  try {
    reqBody = getMailRecipientRequestBody(rBody);
  } catch (error) {
    perr(`Failed to process mail recipient input; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let resBody: MailRecipientResponseBody | undefined;

  try {
    const { uuid = '' } = execManageAlerts('recipients', 'add', {
      body: reqBody,
    });

    resBody = { uuid };
  } catch (error) {
    perr(`Failed to create mail recipient; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(201).send(resBody);
};
