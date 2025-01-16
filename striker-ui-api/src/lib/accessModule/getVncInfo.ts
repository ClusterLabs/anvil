import { query } from './query';
import { poutvar } from '../shell';

export const getVncinfo = async (
  serverUuid: string,
): Promise<ServerDetailVncInfo> => {
  const rows: [[string]] = await query(
    `SELECT variable_value
      FROM variables
      WHERE variable_name = 'server::${serverUuid}::vncinfo';`,
  );

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
