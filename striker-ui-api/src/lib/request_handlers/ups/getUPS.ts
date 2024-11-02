import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getUPS: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const query = `
      SELECT
        ups_uuid,
        ups_name,
        ups_agent,
        ups_ip_address
      FROM upses
      WHERE ups_ip_address != '${DELETED}'
      ORDER BY ups_name ASC;`;

    const afterQueryReturn: QueryResultModifierFunction =
      buildQueryResultReducer<{ [upsUUID: string]: UpsOverview }>(
        (previous, [upsUUID, upsName, upsAgent, upsIPAddress]) => {
          previous[upsUUID] = {
            upsAgent,
            upsIPAddress,
            upsName,
            upsUUID,
          };

          return previous;
        },
        {},
      );

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
