import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { sanitize } from '../../sanitize';

export const getMailServerDetail: RequestHandler<MailServerParamsDictionary> =
  buildGetRequestHandler((request, options) => {
    const {
      params: { uuid: rUuid },
    } = request;

    const uuid = sanitize(rUuid, 'string', { modifierType: 'sql' });

    const query = `
      SELECT
        a.mail_server_uuid,
        a.mail_server_address,
        a.mail_server_port,
        a.mail_server_username,
        a.mail_server_password,
        a.mail_server_security,
        a.mail_server_authentication,
        a.mail_server_helo_domain
      FROM mail_servers AS a
      WHERE a.mail_server_helo_domain != '${DELETED}'
        AND a.mail_server_uuid = '${uuid}'
      ORDER BY a.mail_server_address ASC;`;

    const afterQueryReturn: QueryResultModifierFunction =
      buildQueryResultModifier<MailServerDetail | undefined>((rows) => {
        if (!rows.length) {
          return undefined;
        }

        const {
          0: [
            uuid,
            address,
            port,
            username,
            password,
            security,
            authentication,
            heloDomain,
          ],
        } = rows;

        return {
          address,
          authentication,
          heloDomain,
          password,
          port: Number(port),
          security,
          username,
          uuid,
        };
      });

    if (options) {
      options.afterQueryReturn = afterQueryReturn;
    }

    return query;
  });
