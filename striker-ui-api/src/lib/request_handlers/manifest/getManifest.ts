import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getManifest: RequestHandler = buildGetRequestHandler(
  (response, buildQueryOptions) => {
    const query = `
      SELECT
        manifest_uuid,
        manifest_name
      FROM manifests
      ORDER BY manifest_name ASC;`;
    const afterQueryReturn: QueryResultModifierFunction | undefined =
      buildQueryResultReducer<{ [manifestUUID: string]: ManifestOverview }>(
        (previous, [manifestUUID, manifestName]) => {
          previous[manifestUUID] = {
            manifestName,
            manifestUUID,
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
