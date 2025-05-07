import { RequestHandler } from 'express';

import { getLocalHostUUID, query } from '../../accessModule';
import { buildHostDetailList } from './buildHostDetailList';
import { toLocal } from '../../convertHostUUID';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { Responder } from '../../Responder';
import { getHostQueryStringSchema } from './schemas';
import { sqlHosts } from '../../sqls';

export const getHost: RequestHandler<
  Express.RhParamsDictionary,
  HostOverviewList | HostDetailList,
  Express.RhReqBody,
  {
    detail?: boolean;
    node?: string | string[];
    type?: string | string[];
  }
> = async (request, response) => {
  const respond = new Responder(response);

  let qs: {
    detail?: boolean;
    host?: string[];
    node?: string[];
    type?: string[];
  };

  try {
    qs = await getHostQueryStringSchema.validate(request.query);
  } catch (error) {
    return respond.s400(
      'b57aa0f',
      `Invalid request query string(s); CAUSE: ${error}`,
    );
  }

  const { detail, host: lshost, node: lsnode, type: lstype } = qs;

  if (detail) {
    let hosts: HostDetailList;

    try {
      hosts = await buildHostDetailList({ lshost, lsnode, lstype });
    } catch (error) {
      return respond.s500(
        '4fd118b',
        `Failed to get host detail list; CAUSE: ${error}`,
      );
    }

    return respond.s200(hosts);
  }

  let condition = `TRUE`;

  if (lsnode) {
    condition += join(lsnode, {
      beforeReturn: (csv) => csv && ` AND b.anvil_uuid IN (${csv})`,
      elementWrapper: "'",
      separator: ', ',
    });
  }

  if (lstype) {
    condition += join(lstype, {
      beforeReturn: (csv) => csv && ` AND a.host_type IN (${csv})`,
      elementWrapper: "'",
      separator: ', ',
    });
  }

  const sqlGetHosts = `
    SELECT
      a.host_name,
      a.host_status,
      a.host_type,
      a.host_uuid,
      b.anvil_uuid,
      b.anvil_name,
      c.variable_value
    FROM (${sqlHosts()}) AS a
    LEFT JOIN anvils AS b
      ON a.host_uuid IN (
        b.anvil_node1_host_uuid,
        b.anvil_node2_host_uuid
      )
    LEFT JOIN variables AS c
      ON c.variable_name = 'system::configured'
        AND c.variable_source_table = 'hosts'
        AND a.host_uuid = c.variable_source_uuid
    ${condition}
    ORDER BY a.host_name;`;

  let hostRows: string[][];

  try {
    hostRows = await query(sqlGetHosts);
  } catch (error) {
    return respond.s500('43476da', `Failed to get host list; CAUSE: ${error}`);
  }

  const localHostUuid: string = getLocalHostUUID();

  const hosts: Record<string, HostOverview> = {};

  hostRows.forEach((row) => {
    const [
      hostName,
      hostStatus,
      hostType,
      hostUuid,
      anvilUuid,
      anvilName,
      hostConfigured,
    ] = row;

    const key = toLocal(hostUuid, localHostUuid);

    let anvil: HostOverview['anvil'];

    if (anvilUuid) {
      anvil = { name: anvilName, uuid: anvilUuid };
    }

    hosts[key] = {
      anvil,
      hostConfigured: hostConfigured === '1',
      hostName,
      hostStatus,
      hostType,
      hostUUID: hostUuid,
      shortHostName: getShortHostName(hostName),
    };
  });

  return respond.s200(hosts);
};
