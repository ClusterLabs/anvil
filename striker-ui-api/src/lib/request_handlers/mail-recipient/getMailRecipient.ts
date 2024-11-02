import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getMailRecipient: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const query = `
      SELECT
        a.recipient_uuid,
        a.recipient_name
      FROM recipients AS a
      WHERE a.recipient_name != '${DELETED}'
      ORDER BY a.recipient_name ASC;`;

    const afterQueryReturn: QueryResultModifierFunction =
      buildQueryResultReducer<MailRecipientOverviewList>(
        (previous, [uuid, name]) => {
          previous[uuid] = { name, uuid };

          return previous;
        },
        {},
      );

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
