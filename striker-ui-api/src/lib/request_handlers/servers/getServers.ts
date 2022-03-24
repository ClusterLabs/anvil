import buildGetRequestHandler from '../buildGetRequestHandler';
import join from '../../join';

const getServers = buildGetRequestHandler((request) => {
  const { anvilsUUID } = request.body;

  const condAnvilsUUID = join(anvilsUUID, {
    beforeReturn: (toReturn) =>
      toReturn ? `AND server_anvil_uuid IN (${toReturn})` : '',
    elementWrapper: "'",
    separator: ', ',
  });

  console.log(`condAnvilsUUID=[${condAnvilsUUID}]`);

  return `
    SELECT
      server_uuid,
      server_name,
      server_state,
      server_host_uuid
    FROM servers
    WHERE server_state != 'DELETED'
      ${condAnvilsUUID};`;
});

export default getServers;
