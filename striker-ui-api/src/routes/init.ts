import express from 'express';

import { getLocalHostUUID, query } from '../lib/accessModule';
import { stderr, stdoutVar } from '../lib/shell';

import { setMapNetwork } from '../lib/request_handlers/command';
import { configStriker } from '../lib/request_handlers/host';
import { getNetworkInterface } from '../lib/request_handlers/network-interface';

const router = express.Router();

router.use(async (request, response, next) => {
  const localHostUuid = getLocalHostUUID();

  let rows: [[string]];

  try {
    rows = await query(
      `SELECT variable_value
        FROM variables
        WHERE variable_name = 'system::configured'
          AND variable_source_table = 'hosts'
          AND variable_source_uuid = '${localHostUuid}'
        LIMIT 1;`,
    );
  } catch (error) {
    stderr(`Failed to get system configured flag; CAUSE: ${error}`);

    return response.status(500).send();
  }

  stdoutVar(rows, `system::configured=`);

  if (rows.length === 1 && rows[0][0] === '1') {
    stderr(
      `The init endpoints cannot be used after initializing the local striker`,
    );

    return response.status(401).send();
  }

  return next();
});

router
  .get('/network-interface', getNetworkInterface)
  .post('/', configStriker)
  .put('/set-map-network', setMapNetwork);

export default router;
