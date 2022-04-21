import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryAnvilDetail from './buildQueryAnvilDetail';

const getAnvil = buildGetRequestHandler((request, buildQueryOptions) => {
  const { anvilsUUID, isForProvisionServer } = request.body;

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

  if (anvilsUUID) {
    const {
      query: anvilDetailQuery,
      afterQueryReturn: anvilDetailAfterQueryReturn,
    } = buildQueryAnvilDetail({
      anvilsUUID,
      isForProvisionServer,
    });

    query = anvilDetailQuery;

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = anvilDetailAfterQueryReturn;
    }
  }

  return query;
});

export default getAnvil;