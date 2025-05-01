import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildHostDetailList } from './buildHostDetail';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { Responder } from '../../Responder';
import { getHostQueryStringSchema } from './schemas';

export const getHost = buildGetRequestHandler<
  Express.RhParamsDictionary,
  HostOverviewList,
  Express.RhReqBody,
  {
    node?: string | string[];
    type?: string | string[];
  }
>(async (request, hooks) => {
  const qs = await getHostQueryStringSchema.validate(request.query);

  const { node: lsnode, type: lstype } = qs;

  const localHostUuid: string = getLocalHostUUID();

  let condition = `WHERE a.host_key != '${DELETED}'`;

  if (lsnode) {
    condition += join(lsnode, {
      beforeReturn: (csv) => (csv ? ` AND b.anvil_uuid IN (${csv})` : ''),
      elementWrapper: "'",
      separator: ', ',
    });
  }

  if (lstype) {
    condition += join(lstype, {
      beforeReturn: (csv) => (csv ? ` AND a.host_type IN (${csv})` : ''),
      elementWrapper: "'",
      separator: ', ',
    });
  }

  const query = `
    SELECT
      a.host_name,
      a.host_status,
      a.host_type,
      a.host_uuid,
      b.anvil_uuid,
      b.anvil_name,
      c.variable_value
    FROM hosts AS a
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
    ORDER BY a.host_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<{ [hostUUID: string]: HostOverview }>(
      (previous, row) => {
        const [
          hostName,
          hostStatus,
          hostType,
          hostUuid,
          anUuid,
          anName,
          hostConfigured,
        ] = row;

        const key = toLocal(hostUuid, localHostUuid);

        let anvil: HostOverview['anvil'];

        if (anUuid) {
          anvil = { name: anName, uuid: anUuid };
        }

        previous[key] = {
          anvil,
          hostConfigured: hostConfigured === '1',
          hostName,
          hostStatus,
          hostType,
          hostUUID: hostUuid,
          shortHostName: getShortHostName(hostName),
        };

        return previous;
      },
      {},
    );

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});

export const getHostAlt: RequestHandler<
  Express.RhParamsDictionary,
  HostDetailList
> = async (request, response) => {
  const respond = new Responder(response);

  let hosts: HostDetailList;

  try {
    hosts = await buildHostDetailList();
  } catch (error) {
    return respond.s500(
      '4fd118b',
      `Failed to get host detail list; CAUSE: ${error}`,
    );
  }

  return respond.s200(hosts);
};
