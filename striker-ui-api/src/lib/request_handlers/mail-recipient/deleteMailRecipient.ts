import { RequestHandler } from 'express';

import { query } from '../../accessModule';
import { execManageAlerts } from '../../execManageAlerts';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

export const deleteMailRecipient: RequestHandler<
  MailRecipientParamsDictionary
> = async (request, response) => {
  const {
    params: { uuid: rUuid },
  } = request;

  const uuid = sanitize(rUuid, 'string', { modifierType: 'sql' });

  try {
    const rows = await query<[string][]>(
      `SELECT alert_override_uuid
        FROM alert_overrides
        WHERE alert_override_alert_level != -1
          AND alert_override_recipient_uuid = '${uuid}';`,
    );

    rows.forEach(([u]) =>
      execManageAlerts('alert-overrides', 'delete', { uuid: u }),
    );
  } catch (error) {
    perr(`Failed to delete related alert override records; CAUSE ${error}`);

    return response.status(500).send();
  }

  try {
    execManageAlerts('recipients', 'delete', { uuid });
  } catch (error) {
    perr(`Failed to delete alert recipient; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.status(204).send();
};
