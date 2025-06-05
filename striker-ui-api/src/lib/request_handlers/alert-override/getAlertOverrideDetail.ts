import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { sanitize } from '../../sanitize';
import { sqlHosts, sqlRecipients } from '../../sqls';

export const getAlertOverrideDetail = buildGetRequestHandler<
  AlertOverrideReqParams,
  AlertOverrideDetail
>((request, hooks) => {
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
        a.recipient_email,
        a.recipient_level,
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
          a.alert_override_uuid = '${uuid}'
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
      } = rows;

      return {
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
    });

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
