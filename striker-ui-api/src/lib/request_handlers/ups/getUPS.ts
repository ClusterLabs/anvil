import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getUPS: RequestHandler = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const query = `
      SELECT
        ups_uuid,
        ups_name,
        ups_agent,
        ups_ip_address
      FROM upses
      ORDER BY ups_name ASC;`;
    const afterQueryReturn: QueryResultModifierFunction | undefined =
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

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = afterQueryReturn;
    }

    return query;
  },
);
