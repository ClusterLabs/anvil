import { query } from './query';
import { poutvar } from '../shell';

export const getVncinfo = async (
  serverUuid: string,
): Promise<ServerDetailVncInfo> => {
  const sqlGetVncInfo = `
    SELECT a.variable_value
    FROM variables AS a
    JOIN (
      SELECT *
      FROM servers
      WHERE
          server_state IN ('running')
        AND
          server_uuid = '${serverUuid}'
    ) AS b
      ON a.variable_name = CONCAT('server::', b.server_uuid, '::vncinfo');`;

  const rows: [[string]] = await query(sqlGetVncInfo);

  if (!rows.length) {
    throw new Error('No record found');
  }

  const [[vncinfo]] = rows;
  const [domain, rPort] = vncinfo.split(':');

  const port = Number(rPort);
  const protocol = 'ws';

  const result: ServerDetailVncInfo = {
    domain,
    port,
    protocol,
  };

  poutvar(result, `VNC info for server [${serverUuid}]: `);

  return result;
};
