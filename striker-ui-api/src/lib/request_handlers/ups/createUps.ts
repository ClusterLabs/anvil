import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_IPV4, REP_PEACEFUL_STRING, REP_UUID } from '../../consts';

import { timestamp, write } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr, uuid } from '../../shell';

export const createUps: RequestHandler<
  { uuid?: string },
  undefined,
  { agent: string; ipAddress: string; name: string }
> = async (request, response) => {
  const {
    body: { agent: rAgent, ipAddress: rIpAddress, name: rName } = {},
    params: { uuid: rUuid },
  } = request;

  const agent = sanitize(rAgent, 'string');
  const ipAddress = sanitize(rIpAddress, 'string');
  const name = sanitize(rName, 'string');
  const upsUuid = sanitize(rUuid, 'string', { fallback: uuid() });

  try {
    assert(
      REP_PEACEFUL_STRING.test(agent),
      `Agent must be a peaceful string; got [${agent}]`,
    );

    assert(
      REP_IPV4.test(ipAddress),
      `IP address must be a valid IPv4; got [${ipAddress}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(name),
      `Name must be a peaceful string; got [${name}]`,
    );

    assert(
      REP_UUID.test(upsUuid),
      `UPS UUID must be a valid UUIDv4; got [${upsUuid}]`,
    );
  } catch (error) {
    perr(`Assert value failed when working with UPS; CAUSE: ${error}`);

    return response.status(400).send();
  }

  const modifiedDate = timestamp();

  try {
    const wcode = await write(
      `INSERT INTO
        upses (
          ups_uuid,
          ups_name,
          ups_agent,
          ups_ip_address,
          modified_date
        ) VALUES (
          '${upsUuid}',
          '${name}',
          '${agent}',
          '${ipAddress}',
          '${modifiedDate}'
        ) ON CONFLICT (ups_uuid)
          DO UPDATE SET
            ups_name = '${name}',
            ups_agent = '${agent}',
            ups_ip_address = '${ipAddress}',
            modified_date = '${modifiedDate}';`,
    );

    assert(wcode === 0, `Write exited with code ${wcode}`);
  } catch (error) {
    perr(`Failed to write UPS record; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const scode = rUuid ? 200 : 201;

  return response.status(scode).send();
};
