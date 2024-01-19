import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { getShortHostName } from '../../disassembleHostName';

export const getAlertOverride: RequestHandler<
  AlertOverrideReqParams,
  undefined,
  undefined,
  AlertOverrideReqQuery
> = buildGetRequestHandler((request, options) => {
  const {
    query: { 'mail-recipient': mailRecipient },
  } = request;

  const { after: mailRecipientCond } = buildUnknownIDCondition(
    mailRecipient,
    'b.recipient_uuid',
    { onFallback: () => 'TRUE' },
  );

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
        AND ${mailRecipientCond}
      ORDER BY b.recipient_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultReducer<AlertOverrideOverviewList>(
      (
        previous,
        [
          uuid,
          level,
          mailRecipientUuid,
          mailRecipientName,
          hostUuid,
          hostName,
          hostType,
        ],
      ) => {
        previous[uuid] = {
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

        return previous;
      },
      {},
    );

  if (options) {
    options.afterQueryReturn = afterQueryReturn;
  }

  return query;
});
