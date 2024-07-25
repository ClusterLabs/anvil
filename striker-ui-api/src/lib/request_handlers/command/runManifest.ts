import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_PEACEFUL_STRING, REP_UUID } from '../../consts/REG_EXP_PATTERNS';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import {
  getData,
  getHostData,
  getManifestData,
  job,
  query,
  sub,
} from '../../accessModule';
import { ResponseError } from '../../ResponseError';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

export const runManifest: RequestHandler<
  { manifestUuid: string },
  undefined | ResponseErrorBody,
  RunManifestRequestBody
> = async (request, response) => {
  const {
    params: { manifestUuid: rawManifestUuid },
    body: {
      debug = 2,
      description: rawDescription,
      hosts: rawHostList = {},
      password: rawPassword,
      rerun: rawRerun,
      reuseHosts: rawReuseHosts,
    } = {},
  } = request;

  const manifestUuid = sanitize(rawManifestUuid, 'string', {
    modifierType: 'sql',
  });
  const rerun = sanitize(rawRerun, 'boolean');
  const reuseHosts = sanitize(rawReuseHosts, 'boolean');

  let description = sanitize(rawDescription, 'string');
  let password = sanitize(rawPassword, 'string');

  const hostList: ManifestExecutionHostList = {};

  const handleAssertError = (assertError: unknown) => {
    perr(
      `Failed to assert value when trying to run manifest ${manifestUuid}; CAUSE: ${assertError}`,
    );

    response.status(400).send();
  };

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
      const rserror = new ResponseError(
        '49e0e02',
        `Failed to get existing record with manifest [${manifestUuid}]; CAUSE: ${error}`,
      );

      perr(rserror.toString());

      return response.status(500).send(rserror.body);
    }

    if (!rows.length) {
      const rserror = new ResponseError(
        '2d42e16',
        `No record found on rerun manifest [${manifestUuid}]`,
      );

      perr(rserror.toString());

      return response.status(404).send(rserror.body);
    }

    // Assign existing values before value assertions.
    ({
      0: [description, password],
    } = rows);
  }

  try {
    assert(
      REP_PEACEFUL_STRING.test(description),
      `Description must be a peaceful string; got: [${description}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(password),
      `Password must be a peaceful string; got [${password}]`,
    );

    const uniqueList: Record<string, boolean | undefined> = {};
    const isHostListUnique = !Object.values(rawHostList).some(
      ({ number, type, uuid }) => {
        const id = `${type}${number}`;
        assert(
          /^node[12]$/.test(id),
          `Host ID must be "node" followed by 1 or 2; got [${id}]`,
        );

        assert(
          REP_UUID.test(uuid),
          `Host UUID assigned to ${id} must be a UUIDv4; got [${uuid}]`,
        );

        const isIdDuplicate = Boolean(uniqueList[id]);
        const isUuidDuplicate = Boolean(uniqueList[uuid]);

        uniqueList[id] = true;
        uniqueList[uuid] = true;

        hostList[id] = { id, number, type, uuid };

        return isIdDuplicate || isUuidDuplicate;
      },
    );

    assert(isHostListUnique, `Each entry in hosts must be unique`);
  } catch (assertError) {
    return handleAssertError(assertError);
  }

  let rawHostListData: AnvilDataHostListHash | undefined;
  let rawManifestListData: AnvilDataManifestListHash | undefined;
  let rawSysData: AnvilDataSysHash | undefined;

  try {
    rawHostListData = await getHostData();
    rawManifestListData = await getManifestData(manifestUuid);
    rawSysData = await getData('sys');
  } catch (subError) {
    perr(`Failed to get install manifest ${manifestUuid}; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  if (!rawHostListData || !rawManifestListData || !rawSysData) {
    return response.status(404).send();
  }

  const { host_uuid: hostUuidMapToData } = rawHostListData;
  const {
    manifest_uuid: {
      [manifestUuid]: {
        parsed: { name: manifestName },
      },
    },
  } = rawManifestListData;
  const { hosts: { by_uuid: mapToHostNameData = {} } = {} } = rawSysData;

  const joinAnJobs: JobParams[] = [];

  let anParams: Record<string, string>;

  try {
    anParams = Object.values(hostList).reduce<Record<string, string>>(
      (previous, { id: hostId = '', uuid: hostUuid }) => {
        const hostName = mapToHostNameData[hostUuid];
        const { anvil_name: anName } = hostUuidMapToData[hostUuid];

        if (anName && !reuseHosts) {
          assert(
            anName !== manifestName,
            `Cannot use [${hostName}] for [${manifestName}] because it belongs to [${anName}]; set reuseHost:true to allow this`,
          );
        }

        joinAnJobs.push({
          debug,
          file: __filename,
          job_command: SERVER_PATHS.usr.sbin['anvil-join-anvil'].self,
          job_data: `as_machine=${hostId},manifest_uuid=${manifestUuid}`,
          job_description: 'job_0073',
          job_host_uuid: hostUuid,
          job_name: `join_anvil::${hostId}`,
          job_title: 'job_0072',
        });

        previous[`anvil_${hostId}_host_uuid`] = hostUuid;

        return previous;
      },
      {
        anvil_description: description,
        anvil_name: manifestName,
        anvil_password: password,
      },
    );
  } catch (assertError) {
    handleAssertError(assertError);

    return;
  }

  try {
    const [newAnUuid]: [string] = await sub('insert_or_update_anvils', {
      params: [anParams],
    });

    for (const jobParams of joinAnJobs) {
      jobParams.job_data += `,anvil_uuid=${newAnUuid}`;

      await job(jobParams);
    }
  } catch (subError) {
    perr(`Failed to record new anvil node entry; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(204).send();
};
