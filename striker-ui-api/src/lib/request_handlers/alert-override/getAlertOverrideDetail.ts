import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { getShortHostName } from '../../disassembleHostName';
import { sanitize } from '../../sanitize';

export const getAlertOverrideDetail: RequestHandler<AlertOverrideReqParams> =
  buildGetRequestHandler((request, options) => {
    const {
      params: { uuid: rUuid },
    } = request;

    const uuid = sanitize(rUuid, 'string', { modifierType: 'sql' });

    const query = `
      SELECT
        a.alert_override_uuid,
        a.alert_override_alert_level,
        b.recipient_uuid,
        b.recipient_name,
        c.host_uuid,
        c.host_name,
        c.host_type
      FROM alert_overrides AS a
      JOIN recipients AS b
        ON a.alert_override_recipient_uuid = b.recipient_uuid
      JOIN hosts AS c
        ON a.alert_override_host_uuid = c.host_uuid
      WHERE a.alert_override_alert_level != -1
        AND b.recipient_name != '${DELETED}'
        AND a.alert_override_uuid = '${uuid}'
      ORDER BY b.recipient_name ASC;`;

    const afterQueryReturn: QueryResultModifierFunction =
      buildQueryResultModifier<AlertOverrideDetail | undefined>((rows) => {
        if (!rows.length) {
          return undefined;
        }

        const {
          0: [
            uuid,
            level,
            mailRecipientUuid,
            mailRecipientName,
            hostUuid,
            hostName,
            hostType,
          ],
        } = rows;

        return {
          host: {
            hostName,
            hostType,
            hostUUID: hostUuid,
            shortHostName: getShortHostName(hostName),
          },
          level: Number(level),
          mailRecipient: {
            name: mailRecipientName,
            uuid: mailRecipientUuid,
          },
          uuid,
        };
      });

    if (options) {
      options.afterQueryReturn = afterQueryReturn;
    }

    return query;
  });
