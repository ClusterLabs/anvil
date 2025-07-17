import { RequestHandler } from 'express';

import { query } from '../../accessModule';
import { execManageAlerts } from '../../execManageAlerts';
import { Responder } from '../../Responder';
import { sqlAlertOverrides } from '../../sqls';

export const deleteMailRecipient: RequestHandler<
  MailRecipientParamsDictionary,
  Express.RhResBody,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const { uuid } = response.locals.target;

  const sqlGetAlertOverride = `
    SELECT a.alert_override_uuid
    FROM (${sqlAlertOverrides()}) AS a
    WHERE a.alert_override_recipient_uuid = '${uuid}';`;

  try {
    const rows = await query<[string][]>(sqlGetAlertOverride);

    rows.forEach(([u]) =>
      execManageAlerts('alert-overrides', 'delete', { uuid: u }),
    );
  } catch (error) {
    return respond.s500(
      'ebc4ca1',
      `Failed to delete related alert override records; CAUSE ${error}`,
    );
  }

  try {
    execManageAlerts('recipients', 'delete', { uuid });
  } catch (error) {
    return respond.s500(
      'e4417bd',
      `Failed to delete alert recipient; CAUSE: ${error}`,
    );
  }

  return respond.s204();
};
