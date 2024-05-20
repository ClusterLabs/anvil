import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_IPV4,
  REP_IPV4_CSV,
  REP_PEACEFUL_STRING,
  REP_UUID,
} from '../../consts/REG_EXP_PATTERNS';

import { sub } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { pout } from '../../shell';

export const buildManifest = async (
  ...[request]: Parameters<
    RequestHandler<
      { manifestUuid?: string },
      undefined,
      BuildManifestRequestBody
    >
  >
) => {
  const {
    body: {
      domain: rawDomain,
      hostConfig: { hosts: hostList = {} } = {},
      networkConfig: {
        dnsCsv: rawDns,
        mtu: rawMtu = 1500,
        networks: networkList = {},
        ntpCsv: rawNtp,
      } = {},
      prefix: rawPrefix,
      sequence: rawSequence,
    } = {},
    params: { manifestUuid: rawManifestUuid = 'new' },
  } = request;

  pout('Begin building install manifest.');

  const dns = sanitize(rawDns, 'string');
  const domain = sanitize(rawDomain, 'string');
  const manifestUuid = sanitize(rawManifestUuid, 'string');
  const mtu = sanitize(rawMtu, 'number');
  const ntp = sanitize(rawNtp, 'string');
  const prefix = sanitize(rawPrefix, 'string');
  const sequence = sanitize(rawSequence, 'number');

  try {
    assert(REP_IPV4_CSV.test(dns), `DNS must be an IPv4 CSV; got [${dns}]`);

    assert(
      REP_PEACEFUL_STRING.test(domain),
      `Domain must be a peaceful string; got [${domain}]`,
    );

    assert(
      manifestUuid === 'new' || REP_UUID.test(manifestUuid),
      `Manifest UUID must be a UUIDv4; got [${manifestUuid}]`,
    );

    assert(Number.isSafeInteger(mtu), `MTU must be an integer; got [${mtu}]`);

    if (ntp) {
      assert(REP_IPV4_CSV.test(ntp), `NTP must be an IPv4 CSV; got [${ntp}]`);
    }

    assert(
      REP_PEACEFUL_STRING.test(prefix),
      `Prefix must be a peaceful string; got [${prefix}]`,
    );

    assert(
      Number.isSafeInteger(sequence),
      `Sequence must be an integer; got [${sequence}]`,
    );
  } catch (error) {
    throw new Error(`Failed to assert build manifest input; CAUSE: ${error}`);
  }

  const netCounts: Record<string, number> = {};
  const netConfigs: Record<string, string> = {};

  try {
    Object.values(networkList).forEach((network) => {
      const {
        networkGateway: rawGateway,
        networkMinIp: rawMinIp,
        networkNumber: rawNetworkNumber,
        networkSubnetMask: rawSubnetMask,
        networkType: rawNetworkType,
      } = network;

      const gateway = sanitize(rawGateway, 'string');
      const minIp = sanitize(rawMinIp, 'string');
      const networkNumber = sanitize(rawNetworkNumber, 'number');
      const networkType = sanitize(rawNetworkType, 'string');
      const subnetMask = sanitize(rawSubnetMask, 'string');

      const networkId = `${networkType}${networkNumber}`;

      assert(
        REP_PEACEFUL_STRING.test(networkType),
        `Network type must be a peaceful string; got [${networkType}]`,
      );

      assert(
        Number.isSafeInteger(networkNumber),
        `Network number must be an integer; got [${networkNumber}]`,
      );

      assert(
        REP_IPV4.test(minIp),
        `Minimum IP of ${networkId} must be an IPv4; got [${minIp}]`,
      );

      assert(
        REP_IPV4.test(subnetMask),
        `Subnet mask of ${networkId} must be an IPv4; got [${subnetMask}]`,
      );

      if (networkType === 'ifn') {
        assert(
          REP_IPV4.test(gateway),
          `Gateway of ${networkId} must be an IPv4; got [${gateway}]`,
        );
      }

      const countKey = `${networkType}_count`;
      const countValue = netCounts[countKey] ?? 0;

      netCounts[countKey] = countValue + 1;

      const gatewayKey = `${networkId}_gateway`;
      const minIpKey = `${networkId}_network`;
      const subnetMaskKey = `${networkId}_subnet`;

      netConfigs[gatewayKey] = gateway;
      netConfigs[minIpKey] = minIp;
      netConfigs[subnetMaskKey] = subnetMask;
    });
  } catch (error) {
    throw new Error(`Failed to build networks for manifest; CAUSE: ${error}`);
  }

  const hosts: Record<string, string> = {};

  try {
    Object.values(hostList).forEach((host) => {
      const {
        fences,
        hostNumber: rawHostNumber,
        hostType: rawHostType,
        ipmiIp: rawIpmiIp,
        networks,
        upses,
      } = host;

      const hostNumber = sanitize(rawHostNumber, 'number');
      const hostType = sanitize(rawHostType, 'string');
      const ipmiIp = sanitize(rawIpmiIp, 'string');

      const hostId = `${hostType}${hostNumber}`;

      assert(
        REP_PEACEFUL_STRING.test(hostType),
        `Host type must be a peaceful string; got [${hostType}]`,
      );

      assert(
        Number.isSafeInteger(hostNumber),
        `Host number must be an integer; got [${hostNumber}]`,
      );

      if (ipmiIp) {
        assert(
          REP_IPV4.test(ipmiIp),
          `IPMI IP of ${hostId} must be an IPv4; got [${ipmiIp}]`,
        );

        hosts[`${hostId}_ipmi_ip`] = ipmiIp;
      }

      assert.ok(networks, `Host networks is required`);

      try {
        Object.values(networks).forEach(
          ({
            networkIp: rawIp,
            networkNumber: rawNetworkNumber,
            networkType: rawNetworkType,
          }) => {
            const ip = sanitize(rawIp, 'string');
            const networkNumber = sanitize(rawNetworkNumber, 'number');
            const networkType = sanitize(rawNetworkType, 'string');

            const networkId = `${networkType}${networkNumber}`;

            assert(
              REP_PEACEFUL_STRING.test(networkType),
              `Network type must be a peaceful string; got [${networkType}]`,
            );

            assert(
              Number.isSafeInteger(networkNumber),
              `Network number must be an integer; got [${networkNumber}]`,
            );

            assert(
              REP_IPV4.test(ip),
              `IP of host network ${networkId} must be an IPv4; got [${ip}]`,
            );

            const networkIpKey = `${hostId}_${networkId}_ip`;

            hosts[networkIpKey] = ip;
          },
        );
      } catch (error) {
        throw new Error(
          `Failed to build [${hostId}] networks for manifest; CAUSE: ${error}`,
        );
      }

      try {
        if (fences) {
          Object.values(fences).forEach(
            ({ fenceName: rawFenceName, fencePort: rawPort }) => {
              const fenceName = sanitize(rawFenceName, 'string');
              const port = sanitize(rawPort, 'string');

              assert(
                REP_PEACEFUL_STRING.test(fenceName),
                `Fence name must be a peaceful string; got [${fenceName}]`,
              );

              if (!port) return;

              assert(
                REP_PEACEFUL_STRING.test(port),
                `Port of ${fenceName} must be a peaceful string; got [${port}]`,
              );

              const fenceKey = `${hostId}_fence_${fenceName}`;

              hosts[fenceKey] = port;
            },
          );
        }
      } catch (error) {
        throw new Error(
          `Failed to build [${hostId}] fences for manifest; CAUSE: ${error}`,
        );
      }

      try {
        if (upses) {
          Object.values(upses).forEach(
            ({ isUsed: rawIsUsed, upsName: rawUpsName }) => {
              const upsName = sanitize(rawUpsName, 'string');

              assert(
                REP_PEACEFUL_STRING.test(upsName),
                `UPS name must be a peaceful string; got [${upsName}]`,
              );

              const upsKey = `${hostId}_ups_${upsName}`;

              const isUsed = sanitize(rawIsUsed, 'boolean');

              if (isUsed) {
                hosts[upsKey] = 'checked';
              }
            },
          );
        }
      } catch (error) {
        throw new Error(
          `Failed to build ${hostId} UPSes for manifest; CAUSE: ${error}`,
        );
      }
    });
  } catch (error) {
    throw new Error(`Failed to build hosts for manifest; CAUSE: ${error}`);
  }

  let result: { name: string; uuid: string };

  try {
    const [uuid, name]: [manifestUuid: string, anvilName: string] = await sub(
      'generate_manifest',
      {
        params: [
          {
            dns,
            domain,
            manifest_uuid: manifestUuid,
            mtu,
            ntp,
            prefix,
            sequence,
            ...netCounts,
            ...netConfigs,
            ...hosts,
          },
        ],
        pre: ['Striker'],
      },
    );

    result = { name, uuid };
  } catch (error) {
    throw new Error(`Failed to generate manifest; CAUSE: ${error}`);
  }

  return result;
};
