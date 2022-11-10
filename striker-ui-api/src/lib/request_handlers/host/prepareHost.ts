import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_DOMAIN,
  REP_IPV4,
  REP_PEACEFUL_STRING,
  REP_UUID,
} from '../../consts/REG_EXP_PATTERNS';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job, variable } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stderr } from '../../shell';

export const prepareHost: RequestHandler<
  unknown,
  undefined,
  {
    hostIPAddress: string;
    hostName: string;
    hostPassword: string;
    hostSSHPort?: number;
    hostType: string;
    hostUser?: string;
    hostUUID?: string;
    redhatPassword: string;
    redhatUser: string;
  }
> = (request, response) => {
  const {
    body: {
      hostIPAddress,
      hostName,
      hostPassword,
      hostSSHPort,
      hostType,
      hostUser = 'root',
      hostUUID,
      redhatPassword,
      redhatUser,
    } = {},
  } = request;

  const isHostUUIDProvided = hostUUID !== undefined;

  const dataHostIPAddress = sanitize<'string'>(hostIPAddress);
  const dataHostName = sanitize<'string'>(hostName);
  const dataHostPassword = sanitize<'string'>(hostPassword);
  const dataHostSSHPort = sanitize<'number'>(hostSSHPort) || 22;
  const dataHostType = sanitize<'string'>(hostType);
  const dataHostUser = sanitize<'string'>(hostUser);
  const dataHostUUID = sanitize<'string'>(hostUUID);
  const dataRedhatPassword = sanitize<'string'>(redhatPassword);
  const dataRedhatUser = sanitize<'string'>(redhatUser);

  try {
    assert(
      REP_IPV4.test(dataHostIPAddress),
      `Data host IP address must be a valid IPv4 address; got [${dataHostIPAddress}]`,
    );

    assert(
      REP_DOMAIN.test(dataHostName),
      `Data host name can only contain alphanumeric, hyphen, and dot characters; got [${dataHostName}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(dataHostPassword),
      `Data host password must be peaceful string; got [${dataHostPassword}]`,
    );

    assert(
      /^node|dr$/.test(dataHostType),
      `Data host type must be one of "node" or "dr"; got [${dataHostType}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(dataHostUser),
      `Data host user must be a peaceful string; got [${dataHostUser}]`,
    );

    if (isHostUUIDProvided) {
      assert(
        REP_UUID.test(dataHostUUID),
        `Data host UUID must be a valid UUIDv4; got [${dataHostUUID}]`,
      );
    }

    assert(
      REP_PEACEFUL_STRING.test(dataRedhatPassword),
      `Data redhat password must be a peaceful string; got [${dataRedhatPassword}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(dataRedhatUser),
      `Data redhat user must be a peaceful string; got [${dataRedhatUser}]`,
    );
  } catch (assertError) {
    stderr(
      `Failed to assert value when trying to prepare host; CAUSE: ${assertError}`,
    );

    response.status(400).send();

    return;
  }

  try {
    if (isHostUUIDProvided) {
      variable({
        file: __filename,
        update_value_only: 1,
        variable_name: 'system::configured',
        variable_source_table: 'hosts',
        variable_source_uuid: dataHostUUID,
        variable_value: 0,
      });
    }

    job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['striker-initialize-host'].self,
      job_data: `host_ip_address=${dataHostIPAddress}
host_name=${dataHostName}
password=${dataHostPassword}
rh_password=${dataRedhatPassword}
rh_user=${dataRedhatUser}
ssh_port=${dataHostSSHPort}
type=${dataHostType}`,
      job_description: 'job_0022',
      job_name: `initialize::${dataHostType}::${dataHostIPAddress}`,
      job_progress: 100,
      job_title: `job_002${dataHostType === 'dr' ? '1' : '0'}`,
    });
  } catch (subError) {
    stderr(`Failed to init host; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  response.status(200).send();
};
