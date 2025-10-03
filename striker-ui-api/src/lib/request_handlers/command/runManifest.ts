import assert from 'assert';
import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { Responder } from '../../Responder';
import {
  getData,
  getHostData,
  getManifestData,
  job,
  query,
  sub,
} from '../../accessModule';
import { buildRunManifestRequestBodySchema } from './schemas';

export const runManifest: RequestHandler<
  Express.RhParamsDictionary,
  undefined | ResponseErrorBody,
  RunManifestRequestBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const { uuid: manifestUuid } = response.locals.target;

  let rawHostListData: AnvilDataHostListHash | undefined;
  let rawManifestListData: AnvilDataManifestListHash | undefined;
  let rawSysData: AnvilDataSysHash | undefined;

  try {
    rawHostListData = await getHostData();
    rawManifestListData = await getManifestData(manifestUuid);
    rawSysData = await getData('sys');

    assert.ok(rawHostListData, `Missing host list data`);
    assert.ok(rawManifestListData, `Missing manifest list data`);
    assert.ok(rawSysData, `Missing sys data`);
  } catch (error) {
    return respond.s500(
      '5342377',
      `Failed to load data related to manifest [${manifestUuid}]; CAUSE: ${error}`,
    );
  }

  const {
    manifest_uuid: {
      [manifestUuid]: {
        parsed: { name: manifestName },
      },
    },
  } = rawManifestListData;

  let body: RunManifestSanitizedRequestBody;

  try {
    body = await buildRunManifestRequestBodySchema({
      hosts: rawHostListData,
      manifest: manifestUuid,
      manifests: rawManifestListData,
      sys: rawSysData,
    }).validate(request.body);
  } catch (error) {
    return respond.s400(
      'd125ada',
      `Failed to assert value when trying to run manifest [${manifestUuid}]; CAUSE: ${error}`,
    );
  }

  const { debug, hosts, rerun } = body;

  let { description, password } = body;

  if (rerun) {
    const sql = `
      SELECT
        a.anvil_description,
        a.anvil_password
      FROM anvils AS a
      JOIN manifests AS b
        ON a.anvil_name = b.manifest_name
      WHERE b.manifest_uuid = '${manifestUuid}';`;

    let rows: string[][];

    try {
      rows = await query<string[][]>(sql);
    } catch (error) {
      return respond.s500(
        '49e0e02',
        `Failed to get existing record with manifest [${manifestUuid}]; CAUSE: ${error}`,
      );
    }

    if (!rows.length) {
      return respond.s500(
        '02a4c3d',
        `Failed to find existing record with manifest [${manifestUuid}] when expected`,
      );
    }

    // Reuse values from the existing setup.
    ({
      0: [description, password],
    } = rows);
  }

  const joinAnvilJobs: JobParams[] = [];

  const anvilSqlParams = Object.values(hosts).reduce<Record<string, string>>(
    (previous, host) => {
      joinAnvilJobs.push({
        debug,
        file: __filename,
        job_command: SERVER_PATHS.usr.sbin['anvil-join-anvil'].self,
        job_data: `as_machine=${host.id},manifest_uuid=${manifestUuid}`,
        job_description: 'job_0073',
        job_host_uuid: host.uuid,
        job_name: `join_anvil::${host.id}`,
        job_title: 'job_0072',
      });

      previous[`anvil_${host.id}_host_uuid`] = host.uuid;

      return previous;
    },
    {
      anvil_description: description,
      anvil_name: manifestName,
      anvil_password: password,
    },
  );

  try {
    const [newAnvilUuid]: [string] = await sub('insert_or_update_anvils', {
      params: [anvilSqlParams],
    });

    for (const jobParams of joinAnvilJobs) {
      jobParams.job_data += `,anvil_uuid=${newAnvilUuid}`;

      await job(jobParams);
    }
  } catch (error) {
    return respond.s500(
      'b301232',
      `Failed to record new anvil node entry; CAUSE: ${error}`,
    );
  }

  return respond.s204();
};
