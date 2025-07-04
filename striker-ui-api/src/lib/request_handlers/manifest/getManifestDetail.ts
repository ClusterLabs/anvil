import { RequestHandler } from 'express';

import { getManifestData, query } from '../../accessModule';
import { getEntityParts } from '../../disassembleEntityId';
import { ResponseError } from '../../ResponseError';
import { perr, pout, poutvar } from '../../shell';
import { sanitize } from '../../sanitize';

const handleSortEntries = <T extends [string, unknown]>(
  [aId]: T,
  [bId]: T,
): number => {
  const { name: at, number: an } = getEntityParts(aId);
  const { name: bt, number: bn } = getEntityParts(bId);

  let result = 0;

  if (at === bt) {
    if (an > bn) {
      result = 1;
    } else if (an < bn) {
      result = -1;
    }
  } else if (at > bt) {
    result = 1;
  } else if (at < bt) {
    result = -1;
  }

  return result;
};

/**
 * This handler sorts networks in ascending order. But, it groups IFNs at the
 * end of the list in ascending order.
 *
 * When the sort callback returns:
 * - positive, element `a` will get a higher index than element `b`
 * - negative, element `a` will get a lower index than element `b`
 * - zero, elements' index will remain unchanged
 */
const handleSortNetworks = <T extends [string, unknown]>(
  [aId]: T,
  [bId]: T,
): number => {
  const isAIfn = /^ifn/.test(aId);
  const isBIfn = /^ifn/.test(bId);
  const { name: at, number: an } = getEntityParts(aId);
  const { name: bt, number: bn } = getEntityParts(bId);

  let result = 0;

  if (at === bt) {
    if (an > bn) {
      result = 1;
    } else if (an < bn) {
      result = -1;
    }
  } else if (isAIfn) {
    result = 1;
  } else if (isBIfn) {
    result = -1;
  } else if (at > bt) {
    result = 1;
  } else if (at < bt) {
    result = -1;
  }

  return result;
};

export const getManifestDetail: RequestHandler = async (request, response) => {
  const {
    params: { manifestUUID: rawManifestUuid },
  } = request;

  const manifestUuid = sanitize(rawManifestUuid, 'string', {
    modifierType: 'sql',
  });

  let rawManifestListData: AnvilDataManifestListHash | undefined;

  try {
    rawManifestListData = await getManifestData(manifestUuid);
  } catch (subError) {
    perr(`Failed to get install manifest ${manifestUuid}; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  poutvar(rawManifestListData, 'Raw install manifest list: ');

  if (!rawManifestListData) {
    response.status(404).send();

    return;
  }

  const {
    manifest_uuid: {
      [manifestUuid]: {
        parsed: {
          domain,
          fences: fenceUuidList = {},
          machine,
          name,
          networks: { dns: dnsCsv, mtu, name: networkList, ntp: ntpCsv },
          prefix,
          sequence,
          upses: upsUuidList = {},
        },
      },
    },
  } = rawManifestListData;

  const sql = `
    SELECT
      anvil_uuid,
      anvil_description,
      anvil_node1_host_uuid,
      anvil_node2_host_uuid
    FROM anvils
    WHERE anvil_name = '${name}';`;

  let rows: string[][];

  try {
    rows = await query<string[][]>(sql);
  } catch (error) {
    const rserror = new ResponseError(
      '26bd07d',
      `Failed to find existing record with manifest name [${name}]; CAUSE: ${error}`,
    );

    perr(rserror.toString());

    return response.status(500).send(rserror.body);
  }

  let anvil: ManifestDetail['anvil'];

  if (rows.length > 0) {
    const {
      0: [uuid, description, subnode1Uuid, subnode2Uuid],
    } = rows;

    anvil = {
      description,
      hosts: {
        1: { uuid: subnode1Uuid },
        2: { uuid: subnode2Uuid },
      },
      uuid,
    };
  }

  const manifestData: ManifestDetail = {
    anvil,
    domain,
    hostConfig: {
      hosts: Object.entries(machine)
        .sort(handleSortEntries)
        .reduce<ManifestDetailHostList>(
          (
            previous,
            [
              hostId,
              {
                fence = {},
                ipmi_ip: ipmiIp,
                name: hostName,
                network,
                ups = {},
              },
            ],
          ) => {
            const { name: hostType, number: hostNumber } =
              getEntityParts(hostId);

            pout(`host=${hostType},n=${hostNumber}`);

            // Only include node-type host(s).
            if (hostType !== 'node') {
              return previous;
            }

            previous[hostId] = {
              fences: Object.entries(fence)
                .sort(handleSortEntries)
                .reduce<ManifestDetailFenceList>(
                  (fences, [fenceName, { port: fencePort }]) => {
                    const fenceUuidContainer = fenceUuidList[fenceName];

                    if (fenceUuidContainer) {
                      const { uuid: fenceUuid } = fenceUuidContainer;

                      fences[fenceName] = {
                        fenceName,
                        fencePort,
                        fenceUuid,
                      };
                    }

                    return fences;
                  },
                  {},
                ),
              hostName,
              hostNumber,
              hostType,
              ipmiIp,
              networks: Object.entries(network)
                .sort(handleSortNetworks)
                .reduce<ManifestDetailHostNetworkList>(
                  (hostNetworks, [networkId, { ip: networkIp }]) => {
                    const { name: networkType, number: networkNumber } =
                      getEntityParts(networkId);

                    pout(`hostnetwork=${networkType},n=${networkNumber}`);

                    hostNetworks[networkId] = {
                      networkIp,
                      networkNumber,
                      networkType,
                    };

                    return hostNetworks;
                  },
                  {},
                ),
              upses: Object.entries(ups)
                .sort(handleSortEntries)
                .reduce<ManifestDetailUpsList>((upses, [upsName, { used }]) => {
                  const upsUuidContainer = upsUuidList[upsName];

                  if (upsUuidContainer) {
                    const { uuid: upsUuid } = upsUuidContainer;

                    upses[upsName] = {
                      isUsed: Boolean(used),
                      upsName,
                      upsUuid,
                    };
                  }

                  return upses;
                }, {}),
            };

            return previous;
          },
          {},
        ),
    },
    name,
    networkConfig: {
      dnsCsv,
      mtu: Number(mtu),
      networks: Object.entries(networkList)
        .sort(handleSortNetworks)
        .reduce<ManifestDetailNetworkList>(
          (
            networks,
            [
              networkId,
              {
                gateway: networkGateway,
                network: networkMinIp,
                subnet: networkSubnetMask,
              },
            ],
          ) => {
            const { name: networkType, number: networkNumber } =
              getEntityParts(networkId);

            pout(`network=${networkType},n=${networkNumber}`);

            networks[networkId] = {
              networkGateway,
              networkMinIp,
              networkNumber,
              networkSubnetMask,
              networkType,
            };

            return networks;
          },
          {},
        ),
      ntpCsv,
    },
    prefix,
    sequence: Number(sequence),
    uuid: manifestUuid,
  };

  response.status(200).send(manifestData);
};
