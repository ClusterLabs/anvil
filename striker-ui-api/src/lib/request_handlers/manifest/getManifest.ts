import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getManifest: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const query = `
      SELECT
        manifest_uuid,
        manifest_name
      FROM manifests
      WHERE manifest_note != 'DELETED'
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

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
