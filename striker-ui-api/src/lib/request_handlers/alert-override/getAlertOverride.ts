import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { sqlHosts, sqlRecipients } from '../../sqls';

export const getAlertOverride = buildGetRequestHandler<
  AlertOverrideReqParams,
  AlertOverrideOverviewList,
  Express.RhReqBody,
  AlertOverrideReqQuery
>((request, hooks) => {
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
        b.recipient_email,
        b.recipient_level,
        c.host_uuid,
        c.host_name,
        c.host_short_name,
        d.anvil_uuid,
        d.anvil_name
      FROM alert_overrides AS a
      JOIN (${sqlRecipients()}) AS b
        ON a.alert_override_recipient_uuid = b.recipient_uuid
      JOIN (${sqlHosts()}) AS c
        ON a.alert_override_host_uuid = c.host_uuid
      JOIN anvils AS d
        ON c.host_uuid IN (
          d.anvil_node1_host_uuid,
          d.anvil_node2_host_uuid
        )
      WHERE
          a.alert_override_alert_level != -1
        AND
          ${mailRecipientCond}
      ORDER BY b.recipient_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultReducer<AlertOverrideOverviewList>(
      (
        previous,
        [
          uuid,
          level,
          recipientUuid,
          recipientName,
          recipientEmail,
          recipientLevel,
          hostUuid,
          hostName,
          hostShort,
          anvilUuid,
          anvilName,
        ],
      ) => {
        previous[uuid] = {
          level: Number(level),
          mailRecipient: {
            email: recipientEmail,
            level: Number(recipientLevel),
            name: recipientName,
            uuid: recipientUuid,
          },
          node: {
            name: anvilName,
            uuid: anvilUuid,
          },
          subnode: {
            name: hostName,
            short: hostShort,
            uuid: hostUuid,
          },
          uuid,
        };

        return previous;
      },
      {},
    );

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
