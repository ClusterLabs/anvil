import { RequestHandler } from 'express';

import { execManageAlerts } from '../../execManageAlerts';
import { getMailRecipientRequestBody } from './getMailRecipientRequestBody';
import { Responder } from '../../Responder';
import { pout } from '../../shell';

export const updateMailRecipient: RequestHandler<
  MailRecipientParamsDictionary,
  Express.RhResBody,
  MailRecipientRequestBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = (request, response) => {
  const respond = new Responder(response);

  const { body: rBody = {} } = request;

  const { uuid } = response.locals.target;

  pout('Begin updating mail recipient.');

  let body: MailRecipientRequestBody;

  try {
    body = getMailRecipientRequestBody(rBody, uuid);
  } catch (error) {
    return respond.s400(
      'dd56a1a',
      `Failed to process mail recipient input; CAUSE: ${error}`,
    );
  }

  try {
    execManageAlerts('recipients', 'edit', { body, uuid });
  } catch (error) {
    return respond.s500(
      '603e3b0',
      `Failed to update mail recipient; CAUSE: ${error}`,
    );
  }

  return respond.s200();
};
