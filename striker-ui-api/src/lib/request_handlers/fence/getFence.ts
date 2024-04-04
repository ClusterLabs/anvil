import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { pout } from '../../shell';

export const getFence: RequestHandler = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const query = `
      SELECT
        fence_uuid,
        fence_name,
        fence_agent,
        fence_arguments
      FROM fences
      WHERE fence_arguments != '${DELETED}'
      ORDER BY fence_name ASC;`;

    const afterQueryReturn: QueryResultModifierFunction | undefined =
      buildQueryResultReducer<{ [fenceUUID: string]: FenceOverview }>(
        (
          previous,
          [fenceUUID, fenceName, fenceAgent, fenceParametersString],
        ) => {
          const fenceParametersArray = fenceParametersString.match(
            /(?:[^\s'"]+|'[^']*'|"[^"]*")+/g,
          );

          if (!fenceParametersArray) return previous;

          const fenceParameters = fenceParametersArray.reduce<FenceParameters>(
            (previousParameters, parameterString) => {
              const parameterPair = parameterString.split(/=(.*)/, 2);

              if (parameterPair.length !== 2) return previousParameters;

              const [parameterId, parameterValue] = parameterPair;

              previousParameters[parameterId] = parameterValue.replace(
                /['"]/g,
                '',
              );

              return previousParameters;
            },
            {},
          );

          pout(
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
