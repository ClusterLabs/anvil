import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryAnvilDetail from './buildQueryAnvilDetail';
import { sanitize } from '../../sanitize';

export const getAnvil: RequestHandler = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { anvilUUIDs, isForProvisionServer } = request.query;

    let query = `
      SELECT
        anv.anvil_name,
        anv.anvil_uuid,
        anv.anvil_description,
        hos.host_name,
        hos.host_uuid,
        hos.host_type
      FROM anvils AS anv
      JOIN hosts AS hos
        ON hos.host_uuid IN (
          anv.anvil_node1_host_uuid,
          anv.anvil_node2_host_uuid,
          anv.anvil_dr1_host_uuid
        )
      ORDER BY anv.anvil_uuid;`;

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = (queryStdout) => {
        let results = queryStdout;

        if (queryStdout instanceof Array) {
          let rowStage: AnvilOverview | undefined;

          results = queryStdout.reduce<AnvilOverview[]>(
            (
              reducedRows,
              [
                anvilName,
                anvilUUID,
                anvilDescription,
                hostName,
                hostUUID,
                hostType,
              ],
            ) => {
              if (!rowStage || anvilUUID !== rowStage.anvilUUID) {
                {
                  rowStage = {
                    anvilDescription,
                    anvilName,
                    anvilUUID,
                    hosts: [],
                  };

                  reducedRows.push(rowStage);
                }
              }

              rowStage.hosts.push({
                hostName,
                hostType,
                hostUUID,
              });

              return reducedRows;
            },
            [],
          );
        }

        return results;
      };
    }

    if (anvilUUIDs) {
      const {
        query: anvilDetailQuery,
        afterQueryReturn: anvilDetailAfterQueryReturn,
      } = buildQueryAnvilDetail({
        anvilUUIDs: sanitize(anvilUUIDs, 'string[]', {
          modifierType: 'sql',
        }),
        isForProvisionServer: sanitize(isForProvisionServer, 'boolean'),
      });

      query = anvilDetailQuery;

      if (buildQueryOptions) {
        buildQueryOptions.afterQueryReturn = anvilDetailAfterQueryReturn;
      }
    }

    return query;
  },
);
