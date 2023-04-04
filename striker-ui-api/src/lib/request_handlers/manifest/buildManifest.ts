import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_INTEGER,
  REP_IPV4,
  REP_IPV4_CSV,
  REP_PEACEFUL_STRING,
  REP_UUID,
} from '../../consts/REG_EXP_PATTERNS';

import { sub } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stdout } from '../../shell';

export const buildManifest = (
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

  stdout('Begin building install manifest.');

  const dns = sanitize(rawDns, 'string');
  assert(REP_IPV4_CSV.test(dns), `DNS must be an IPv4 CSV; got [${dns}]`);

  const domain = sanitize(rawDomain, 'string');
  assert(
    REP_PEACEFUL_STRING.test(domain),
    `Domain must be a peaceful string; got [${domain}]`,
  );

  const manifestUuid = sanitize(rawManifestUuid, 'string');
  assert(
    REP_UUID.test(manifestUuid),
    `Manifest UUID must be a UUIDv4; got [${manifestUuid}]`,
  );

  const mtu = sanitize(rawMtu, 'number');
  assert(REP_INTEGER.test(String(mtu)), `MTU must be an integer; got [${mtu}]`);

  const ntp = sanitize(rawNtp, 'string');

  if (ntp) {
    assert(REP_IPV4_CSV.test(ntp), `NTP must be an IPv4 CSV; got [${ntp}]`);
  }

  const prefix = sanitize(rawPrefix, 'string');
  assert(
    REP_PEACEFUL_STRING.test(prefix),
    `Prefix must be a peaceful string; got [${prefix}]`,
  );

  const sequence = sanitize(rawSequence, 'number');
  assert(
    REP_INTEGER.test(String(sequence)),
    `Sequence must be an integer; got [${sequence}]`,
  );

  const { counts: networkCountContainer, networks: networkContainer } =
    Object.values(networkList).reduce<{
      counts: Record<string, number>;
      networks: Record<string, string>;
    }>(
      (
        previous,
        {
          networkGateway: rawGateway,
          networkMinIp: rawMinIp,
          networkNumber: rawNetworkNumber,
          networkSubnetMask: rawSubnetMask,
          networkType: rawNetworkType,
        },
      ) => {
        const networkType = sanitize(rawNetworkType, 'string');
        assert(
          REP_PEACEFUL_STRING.test(networkType),
          `Network type must be a peaceful string; got [${networkType}]`,
        );

        const networkNumber = sanitize(rawNetworkNumber, 'number');
        assert(
          REP_INTEGER.test(String(networkNumber)),
          `Network number must be an integer; got [${networkNumber}]`,
        );

        const networkId = `${networkType}${networkNumber}`;

        const gateway = sanitize(rawGateway, 'string');

        if (networkType === 'ifn') {
          assert(
            REP_IPV4.test(gateway),
            `Gateway of ${networkId} must be an IPv4; got [${gateway}]`,
          );
        }

        const minIp = sanitize(rawMinIp, 'string');
        assert(
          REP_IPV4.test(minIp),
          `Minimum IP of ${networkId} must be an IPv4; got [${minIp}]`,
        );

        const subnetMask = sanitize(rawSubnetMask, 'string');
        assert(
          REP_IPV4.test(subnetMask),
          `Subnet mask of ${networkId} must be an IPv4; got [${subnetMask}]`,
        );

        const { counts: countContainer, networks: networkContainer } = previous;

        const countKey = `${networkType}_count`;
        const countValue = countContainer[countKey] ?? 0;

        countContainer[countKey] = countValue + 1;

        const gatewayKey = `${networkId}_gateway`;
        const minIpKey = `${networkId}_network`;
        const subnetMaskKey = `${networkId}_subnet`;

        networkContainer[gatewayKey] = gateway;
        networkContainer[minIpKey] = minIp;
        networkContainer[subnetMaskKey] = subnetMask;

        return previous;
      },
      { counts: {}, networks: {} },
    );

  const hostContainer = Object.values(hostList).reduce<Record<string, string>>(
    (
      previous,
      {
        fences,
        hostNumber: rawHostNumber,
        hostType: rawHostType,
        ipmiIp: rawIpmiIp,
        networks,
        upses,
      },
    ) => {
      const hostType = sanitize(rawHostType, 'string');
      assert(
        REP_PEACEFUL_STRING.test(hostType),
        `Host type must be a peaceful string; got [${hostType}]`,
      );

      const hostNumber = sanitize(rawHostNumber, 'number');
      assert(
        REP_INTEGER.test(String(hostNumber)),
        `Host number must be an integer; got [${hostNumber}]`,
      );

      const hostId = `${hostType}${hostNumber}`;

      const ipmiIp = sanitize(rawIpmiIp, 'string');
      assert(
        REP_IPV4.test(ipmiIp),
        `IPMI IP of ${hostId} must be an IPv4; got [${ipmiIp}]`,
      );

      const ipmiIpKey = `${hostId}_ipmi_ip`;

      previous[ipmiIpKey] = ipmiIp;

      Object.values(networks).forEach(
        ({
          networkIp: rawIp,
          networkNumber: rawNetworkNumber,
          networkType: rawNetworkType,
        }) => {
          const networkType = sanitize(rawNetworkType, 'string');
          assert(
            REP_PEACEFUL_STRING.test(networkType),
            `Network type must be a peaceful string; got [${networkType}]`,
          );

          const networkNumber = sanitize(rawNetworkNumber, 'number');
          assert(
            REP_INTEGER.test(String(networkNumber)),
            `Network number must be an integer; got [${networkNumber}]`,
          );

          const networkId = `${networkType}${networkNumber}`;

          const ip = sanitize(rawIp, 'string');
          assert(
            REP_IPV4.test(ip),
            `IP of host network ${networkId} must be an IPv4; got [${ip}]`,
          );

          const networkIpKey = `${hostId}_${networkId}_ip`;

          previous[networkIpKey] = ip;
        },
      );

      Object.values(fences).forEach(
        ({ fenceName: rawFenceName, fencePort: rawPort }) => {
          const fenceName = sanitize(rawFenceName, 'string');
          assert(
            REP_PEACEFUL_STRING.test(fenceName),
            `Fence name must be a peaceful string; got [${fenceName}]`,
          );

          const fenceKey = `${hostId}_fence_${fenceName}`;

          const port = sanitize(rawPort, 'string');
          assert(
            REP_PEACEFUL_STRING.test(port),
            `Port of ${fenceName} must be a peaceful string; got [${port}]`,
          );

          previous[fenceKey] = port;
        },
      );

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
            previous[upsKey] = 'checked';
          }
        },
      );

      return previous;
    },
    {},
  );

  let result: { name: string; uuid: string } | undefined;

  try {
    const [uuid, name] = sub('generate_manifest', {
      subModuleName: 'Striker',
      subParams: {
        dns,
        domain,
        manifest_uuid: manifestUuid,
        mtu,
        ntp,
        prefix,
        sequence,
        ...networkCountContainer,
        ...networkContainer,
        ...hostContainer,
      },
    }).stdout as [manifestUuid: string, anvilName: string];

    result = { name, uuid };
  } catch (subError) {
    throw new Error(`Failed to generate manifest; CAUSE: ${subError}`);
  }

  return result;
};
