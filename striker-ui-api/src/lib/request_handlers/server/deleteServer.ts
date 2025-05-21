import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_UUID, SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { Responder } from '../../Responder';
import { sanitize } from '../../sanitize';
import { poutvar } from '../../shell';
import { sqlServersWithJobHost } from '../../sqls';

export const deleteServer: RequestHandler<
  { serverUuid?: string },
  undefined,
  { serverUuids: string[] }
> = async (request, response) => {
  const respond = new Responder(response);

  const {
    body: { serverUuids: rServerUuids } = {},
    params: { serverUuid: rServerUuid },
  } = request;

  const serverUuids = sanitize(rServerUuids, 'string[]', {
    modifierType: 'sql',
  });

  if (rServerUuid) {
    serverUuids.push(
      sanitize(rServerUuid, 'string', {
        modifierType: 'sql',
      }),
    );
  }

  poutvar(serverUuids, `Delete servers with: `);

  for (const serverUuid of serverUuids) {
    try {
      assert(
        REP_UUID.test(serverUuid),
        `Server UUID must be a valid UUIDv4; got [${serverUuid}]`,
      );

      const sqlGetJobHost = `
        SELECT a.server_job_host_uuid
        FROM (${sqlServersWithJobHost()}) AS a
        WHERE a.server_uuid = '${serverUuid}';`;

      const rows: [[string]] = await query(sqlGetJobHost);

      assert.ok(rows.length, `Server ${serverUuid} not found`);

      const [[serverHostUuid]] = rows;

      job({
        file: __filename,
        job_command: `${SERVER_PATHS.usr.sbin['anvil-delete-server'].self}`,
        job_data: `server_uuid=${serverUuid}`,
        job_description: 'job_0209',
        job_host_uuid: serverHostUuid,
        job_name: 'server::delete',
        job_title: 'job_0208',
      });
    } catch (error) {
      return respond.s500(
        '88a5776',
        `Failed to initiate delete server ${serverUuid}; CAUSE: ${error}`,
      );
    }
  }

  return respond.s204();
};
