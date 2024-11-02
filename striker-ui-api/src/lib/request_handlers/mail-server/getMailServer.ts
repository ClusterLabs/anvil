import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getMailServer: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const query = `
      SELECT
        a.mail_server_uuid,
        a.mail_server_address,
        a.mail_server_port
      FROM mail_servers AS a
      WHERE a.mail_server_helo_domain != '${DELETED}'
      ORDER BY a.mail_server_address;`;

    const afterQueryReturn: QueryResultModifierFunction =
      buildQueryResultReducer<MailServerOverviewList>(
        (previous, [uuid, address, port]) => {
          previous[uuid] = {
            address,
            port: Number(port),
            uuid,
          };

          return previous;
        },
        {},
      );

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
