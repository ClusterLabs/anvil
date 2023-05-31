import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { stdout } from '../../shell';

export const getFence: RequestHandler = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const query = `
      SELECT
        fence_uuid,
        fence_name,
        fence_agent,
        fence_arguments
      FROM fences
      ORDER BY fence_name ASC;`;
    const afterQueryReturn: QueryResultModifierFunction | undefined =
      buildQueryResultReducer<{ [fenceUUID: string]: FenceOverview }>(
        (previous, [fenceUUID, fenceName, fenceAgent, fenceArgumentString]) => {
          const fenceParameters = fenceArgumentString
            .split(/\s+/)
            .reduce<FenceParameters>((previous, parameterPair) => {
              const [parameterId, parameterValue] = parameterPair.split(/=/);

              previous[parameterId] = parameterValue.replace(/['"]/g, '');

              return previous;
            }, {});

          stdout(
            `${fenceAgent}: ${fenceName} (${fenceUUID})\n${JSON.stringify(
              fenceParameters,
              null,
              2,
            )}`,
          );

          previous[fenceUUID] = {
            fenceAgent,
            fenceParameters,
            fenceName,
            fenceUUID,
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
