import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_DOMAIN,
  REP_IPV4,
  REP_PEACEFUL_STRING,
  REP_UUID,
  SERVER_PATHS,
} from '../../consts';

import { job, variable } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

export const prepareHost: RequestHandler<
  unknown,
  undefined,
  PrepareHostRequestBody
> = async (request, response) => {
  const {
    body: {
      enterpriseUUID,
      hostIPAddress,
      hostName,
      hostPassword,
      hostSSHPort,
      hostType,
      hostUser,
      hostUUID,
      redhatPassword,
      redhatUser,
    } = {},
  } = request;

  const isEnterpriseUUIDProvided = Boolean(enterpriseUUID);
  const isHostUUIDProvided = Boolean(hostUUID);
  const isRedhatAccountProvided =
    Boolean(redhatPassword) || Boolean(redhatUser);

  const dataEnterpriseUUID = sanitize(enterpriseUUID, 'string');
  const dataHostIPAddress = sanitize(hostIPAddress, 'string');
  const dataHostName = sanitize(hostName, 'string');
  const dataHostPassword = sanitize(hostPassword, 'string');
  const dataHostSSHPort = sanitize(hostSSHPort, 'number', { fallback: 22 });
  const dataHostType = sanitize(hostType, 'string');
  // Host user is unused at the moment.
  const dataHostUser = sanitize(hostUser, 'string', { fallback: 'root' });
  const dataHostUUID = sanitize(hostUUID, 'string');
  const dataRedhatPassword = sanitize(redhatPassword, 'string');
  const dataRedhatUser = sanitize(redhatUser, 'string');

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

    if (isEnterpriseUUIDProvided) {
      assert(
        REP_UUID.test(dataEnterpriseUUID),
        `Data enterprise UUID must be a valid UUIDv4; got [${dataEnterpriseUUID}]`,
      );
    }

    if (isHostUUIDProvided) {
      assert(
        REP_UUID.test(dataHostUUID),
        `Data host UUID must be a valid UUIDv4; got [${dataHostUUID}]`,
      );
    }

    if (isRedhatAccountProvided) {
      assert(
        REP_PEACEFUL_STRING.test(dataRedhatPassword),
        `Data redhat password must be a peaceful string; got [${dataRedhatPassword}]`,
      );

      assert(
        REP_PEACEFUL_STRING.test(dataRedhatUser),
        `Data redhat user must be a peaceful string; got [${dataRedhatUser}]`,
      );
    }
  } catch (assertError) {
    perr(
      `Failed to assert value when trying to prepare host; CAUSE: ${assertError}`,
    );

    return response.status(400).send();
  }

  try {
    if (isHostUUIDProvided) {
      await variable({
        file: __filename,
        update_value_only: 1,
        variable_name: 'system::configured',
        variable_source_table: 'hosts',
        variable_source_uuid: dataHostUUID,
        variable_value: 0,
      });
    }

    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['striker-initialize-host'].self,
      job_data: buildJobDataFromObject({
        enterprise_uuid: dataEnterpriseUUID,
        host_ip_address: dataHostIPAddress,
        host_name: dataHostName,
        password: dataHostPassword,
        rh_password: dataRedhatPassword,
        rh_user: dataRedhatUser,
        ssh_port: dataHostSSHPort,
        type: dataHostType,
      }),
      job_description: 'job_0022',
      job_name: `initialize::${dataHostType}::${dataHostIPAddress}`,
      job_title: `job_002${dataHostType === 'dr' ? '1' : '0'}`,
    });
  } catch (subError) {
    perr(`Failed to init host; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(200).send();
};
