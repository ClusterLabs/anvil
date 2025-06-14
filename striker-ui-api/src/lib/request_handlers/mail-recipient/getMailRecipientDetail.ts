import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { sqlRecipients } from '../../sqls';

export const getMailRecipientDetail = buildGetRequestHandler<
  MailRecipientParamsDictionary,
  MailRecipientDetail,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
>((request, hooks, response) => {
  const { uuid } = response.locals.target;

  const query = `
    SELECT
      a.recipient_uuid,
      a.recipient_name,
      a.recipient_email,
      a.recipient_language,
      a.recipient_level
    FROM (${sqlRecipients()}) AS a
    WHERE a.recipient_uuid = '${uuid}'
    ORDER BY a.recipient_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier<MailRecipientDetail | undefined>((rows) => {
      if (!rows.length) {
        return undefined;
      }

      const {
        0: [uuid, name, email, language, level],
      } = rows;

      return {
        email,
        language,
        level: Number(level),
        name,
        uuid,
      };
    });

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
