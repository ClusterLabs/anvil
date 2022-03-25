import buildGetRequestHandler from '../buildGetRequestHandler';

const getAnvil = buildGetRequestHandler((request, options) => {
  const { anvilsUUID } = request.body;

  let query = `
    SELECT
      anv.anvil_name,
      anv.anvil_uuid,
      hos.host_name,
      hos.host_uuid
    FROM anvils AS anv
    JOIN hosts AS hos
      ON anv.anvil_uuid = hos.host_anvil_uuid;`;

  if (options) {
    options.afterQueryReturn = (queryStdout) => {
      let results = queryStdout;

      if (queryStdout instanceof Array) {
        let rowStage: AnvilOverview;

        results = queryStdout.reduce<AnvilOverview[]>(
          (reducedRows, [anvilName, anvilUUID, hostName, hostUUID]) => {
            if (rowStage && anvilUUID === rowStage.anvilUUID) {
              rowStage.hosts.push({ hostName, hostUUID });
            } else {
              rowStage = {
                anvilName,
                anvilUUID,
                hosts: [],
              };

              reducedRows.push(rowStage);
            }

            return reducedRows;
          },
          [],
        );
      }

      return results;
    };
  }

  if (anvilsUUID) {
    query = 'SELECT * FROM anvils;';
  }

  return query;
});

export default getAnvil;
