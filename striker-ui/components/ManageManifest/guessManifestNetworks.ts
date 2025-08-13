import { Netmask } from 'netmask';

import guessHostNetwork from './guessHostNetwork';
import { ManifestFormikValues } from './schemas/buildManifestSchema';

import {
  INPUT_ID_AH_IPMI_IP,
  INPUT_ID_AH_NETWORK_IP,
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
  INPUT_ID_AN_GATEWAY,
  INPUT_ID_AN_MIN_IP,
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
  INPUT_ID_AN_SUBNET_MASK,
} from './inputIds';

const guessManifestNetworks = <V extends ManifestFormikValues>({
  getFieldChanged,
  hosts,
  values,
}: Partial<Pick<FormikUtils<V>, 'getFieldChanged'>> & {
  hosts: APIHostDetailList;
  values: ManifestFormikValues;
}): ManifestFormikValues => {
  const {
    [INPUT_ID_AI_DOMAIN]: domain,
    [INPUT_ID_AI_PREFIX]: prefix,
    [INPUT_ID_AI_SEQUENCE]: nodeSequence,
  } = values;

  // Make a copy of the current form values for guessing.

  const guessed = { ...values };

  // 1. guess properties of all subnets

  const networkEntries = Object.entries(values.netconf.networks);

  networkEntries.forEach((entry) => {
    const [networkId, network] = entry;

    const {
      [INPUT_ID_AN_NETWORK_NUMBER]: networkSequence = 0,
      [INPUT_ID_AN_NETWORK_TYPE]: networkType,
    } = network;

    const guessedNetwork: ManifestFormikValues['netconf']['networks'][string] =
      {
        ...guessed.netconf.networks[networkId],
      };

    const networkChain = `netconf.networks.${networkId}`;

    if (!getFieldChanged?.(`${networkChain}.${INPUT_ID_AN_MIN_IP}`)) {
      let o2 = 0;

      let minIp: string;

      switch (networkType) {
        case 'bcn':
          o2 = 200 + Number(networkSequence);
          minIp = `10.${o2}.0.0`;
          break;
        case 'mn':
          o2 = 199;
          minIp = `10.${o2}.0.0`;
          break;
        case 'sn':
          o2 = 100 + Number(networkSequence);
          minIp = `10.${o2}.0.0`;
          break;
        default:
          minIp = '';
      }

      guessedNetwork[INPUT_ID_AN_MIN_IP] = minIp;
    }

    guessed.netconf.networks[networkId] = guessedNetwork;
  });

  // 2. guess hosts' BCN, MN, and SN IPs

  const hostEntries = Object.entries(values.hosts);

  hostEntries.forEach((hostEntry) => {
    const [subnodeSequence] = hostEntry;

    networkEntries.forEach((networkEntry) => {
      const [networkId, network] = networkEntry;

      const guessedHostNetwork: ManifestFormikValues['hosts'][string]['networks'][string] =
        {
          ...guessed.hosts[subnodeSequence].networks[networkId],
        };

      const hostNetworkChain = `hosts.${subnodeSequence}.networks.${networkId}`;

      if (!getFieldChanged?.(`${hostNetworkChain}.${INPUT_ID_AH_NETWORK_IP}`)) {
        const ip = guessHostNetwork(
          nodeSequence,
          Number(subnodeSequence),
          network,
        );

        guessedHostNetwork[INPUT_ID_AH_NETWORK_IP] = ip;
      }

      guessed.hosts[subnodeSequence].networks[networkId] = guessedHostNetwork;
    });
  });

  // 3. attempt to find configured host(s) for the manifest

  const matchedHosts = Object.values(hosts).filter((host) => {
    const { name } = host;

    const re = new RegExp(
      `^${prefix}-a${String(nodeSequence).padStart(2, '0')}n\\d{2}\\.${domain}$`,
    );

    return re.test(name);
  });

  // 4. attempt to use values from the configured host(s) for the manifest

  matchedHosts.forEach((host) => {
    const tail = host.short.replace(/^.*n(\d+)$/, '$1');

    const subnodeSequence = Number(tail);

    const { [subnodeSequence]: hostInputs } = guessed.hosts;

    if (!hostInputs) {
      return;
    }

    guessed.hosts[subnodeSequence] = {
      ...guessed.hosts[subnodeSequence],
      [INPUT_ID_AH_IPMI_IP]: host.ipmi.ip,
    };

    networkEntries.forEach((entry) => {
      const [networkId, network] = entry;

      const {
        [INPUT_ID_AN_NETWORK_NUMBER]: networkSequence,
        [INPUT_ID_AN_NETWORK_TYPE]: networkType,
      } = network;

      const key = `${networkType}${networkSequence}`;

      const { [key]: assignedNetwork } = host.netconf.networks;

      if (!assignedNetwork) {
        return;
      }

      const { ip, subnetMask } = assignedNetwork;

      // Begin guessing manifest network by cloning results container
      const guessedNetwork: ManifestFormikValues['netconf']['networks'][string] =
        {
          ...guessed.netconf.networks[networkId],
        };

      const networkChain = `netconf.networks.${networkId}`;

      if (!getFieldChanged?.(`${networkChain}.${INPUT_ID_AN_MIN_IP}`)) {
        let subnet: Netmask;

        try {
          subnet = new Netmask(`${ip}/${subnetMask}`);
        } catch (error) {
          return;
        }

        guessedNetwork[INPUT_ID_AN_MIN_IP] = subnet.base;
      }

      if (!getFieldChanged?.(`${networkChain}.${INPUT_ID_AN_SUBNET_MASK}`)) {
        guessedNetwork[INPUT_ID_AN_SUBNET_MASK] = subnetMask;
      }

      if (
        key === host.netconf.gatewayInterface &&
        !getFieldChanged?.(`${networkChain}.${INPUT_ID_AN_GATEWAY}`)
      ) {
        guessedNetwork[INPUT_ID_AN_GATEWAY] = host.netconf.gateway;
      }

      // End guessing manifest network and assign the results
      guessed.netconf.networks[networkId] = guessedNetwork;

      // Begin guessing manifest **host** network by cloning results container
      const guessedHostNetwork: ManifestFormikValues['hosts'][string]['networks'][string] =
        {
          ...guessed.hosts[subnodeSequence].networks[networkId],
        };

      const hostNetworkChain = `hosts.${subnodeSequence}.networks.${networkId}`;

      if (!getFieldChanged?.(`${hostNetworkChain}.${INPUT_ID_AH_NETWORK_IP}`)) {
        guessedHostNetwork[INPUT_ID_AH_NETWORK_IP] = ip;
      }

      // End guessing manifest **host** network and assign the results
      guessed.hosts[subnodeSequence].networks[networkId] = guessedHostNetwork;
    });
  });

  return guessed;
};

export default guessManifestNetworks;
