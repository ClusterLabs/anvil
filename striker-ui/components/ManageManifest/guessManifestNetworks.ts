import { Netmask } from 'netmask';

import { ManifestFormikValues } from './schemas/buildManifestSchema';

import {
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
}: Pick<FormikUtils<V>, 'getFieldChanged'> & {
  hosts: APIHostDetailList;
  values: ManifestFormikValues;
}): ManifestFormikValues => {
  const {
    [INPUT_ID_AI_DOMAIN]: domain,
    [INPUT_ID_AI_PREFIX]: prefix,
    [INPUT_ID_AI_SEQUENCE]: nodeSequence,
  } = values;

  const matchedHosts = Object.values(hosts).filter((host) => {
    const { name } = host;

    const re = new RegExp(
      `^${prefix}-a${String(nodeSequence).padStart(2, '0')}n\\d{2}\\.${domain}$`,
    );

    return re.test(name);
  });

  const guessed = { ...values };

  matchedHosts.forEach((host) => {
    const tail = host.short.replace(/^.*n(\d+)$/, '$1');

    const subnodeSequence = Number(tail);

    const { [subnodeSequence]: hostInputs } = guessed.hosts;

    if (!hostInputs) {
      return;
    }

    Object.entries(values.netconf.networks).forEach((entry) => {
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

      if (!getFieldChanged(`${networkChain}.${INPUT_ID_AN_MIN_IP}`)) {
        let subnet: Netmask;

        try {
          subnet = new Netmask(`${ip}/${subnetMask}`);
        } catch (error) {
          return;
        }

        guessedNetwork[INPUT_ID_AN_MIN_IP] = subnet.base;
      }

      if (!getFieldChanged(`${networkChain}.${INPUT_ID_AN_SUBNET_MASK}`)) {
        guessedNetwork[INPUT_ID_AN_SUBNET_MASK] = subnetMask;
      }

      if (
        key === host.netconf.gatewayInterface &&
        !getFieldChanged(`${networkChain}.${INPUT_ID_AN_GATEWAY}`)
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

      if (!getFieldChanged(`${hostNetworkChain}.${INPUT_ID_AH_NETWORK_IP}`)) {
        guessedHostNetwork[INPUT_ID_AH_NETWORK_IP] = ip;
      }

      // End guessing manifest **host** network and assign the results
      guessed.hosts[subnodeSequence].networks[networkId] = guessedHostNetwork;
    });
  });

  return guessed;
};

export default guessManifestNetworks;
