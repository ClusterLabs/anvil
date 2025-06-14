import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { sqlRecipients } from '../../sqls';

export const getMailRecipient = buildGetRequestHandler<
  Express.RhParamsDictionary,
  MailRecipientOverviewList
>((request, hooks) => {
  const query = `
    SELECT
      a.recipient_uuid,
      a.recipient_name,
      a.recipient_email,
      a.recipient_level
    FROM (${sqlRecipients()}) AS a
    ORDER BY a.recipient_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultReducer<MailRecipientOverviewList>(
      (previous, [uuid, name, email, level]) => {
        previous[uuid] = {
          email,
          level: Number(level),
          name,
          uuid,
        };

        return previous;
      },
      {},
    );

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
