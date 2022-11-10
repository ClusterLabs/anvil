import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryAnvilDetail from './buildQueryAnvilDetail';
import { sanitize } from '../../sanitize';

const getAnvil: RequestHandler = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { anvilUUIDs, isForProvisionServer } = request.query;

    let query = `
    SELECT
      anv.anvil_name,
      anv.anvil_uuid,
      hos.host_name,
      hos.host_uuid
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
            (reducedRows, [anvilName, anvilUUID, hostName, hostUUID]) => {
              if (!rowStage || anvilUUID !== rowStage.anvilUUID) {
                {
                  rowStage = {
                    anvilName,
                    anvilUUID,
                    hosts: [],
                  };

                  reducedRows.push(rowStage);
                }
              }

              rowStage.hosts.push({ hostName, hostUUID });

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
        anvilUUIDs: sanitize(anvilUUIDs, {
          modifierType: 'sql',
          returnType: 'string[]',
        }),
        isForProvisionServer: sanitize(isForProvisionServer, {
          returnType: 'boolean',
        }),
      });

      query = anvilDetailQuery;

      if (buildQueryOptions) {
        buildQueryOptions.afterQueryReturn = anvilDetailAfterQueryReturn;
      }
    }

    return query;
  },
);

export default getAnvil;
