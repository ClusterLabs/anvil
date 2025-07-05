import { v4 as uuidv4 } from 'uuid';

import guessHostNetwork from './guessHostNetwork';
import guessManifestNetworks from './guessManifestNetworks';
import { ManifestFormikValues } from './schemas/buildManifestSchema';

import {
  INPUT_ID_AH_FENCE_PORT,
  INPUT_ID_AH_IPMI_IP,
  INPUT_ID_AH_NETWORK_IP,
  INPUT_ID_AH_UPS_POWER_HOST,
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
  INPUT_ID_AN_GATEWAY,
  INPUT_ID_AN_MIN_IP,
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
  INPUT_ID_AN_SUBNET_MASK,
  INPUT_ID_ANC_DNS,
  INPUT_ID_ANC_NTP,
} from './inputIds';

const populateHostFence = (
  known: APIManifestTemplateFence[],
  used: ManifestHostFenceList = {},
  initial: ManifestFormikValues['hosts'][string]['fences'] = {},
): typeof initial =>
  known.reduce<typeof initial>((previous, fence) => {
    const { fenceName: name, fenceUUID: uuid } = fence;

    previous[uuid] = {
      [INPUT_ID_AH_FENCE_PORT]: used[name]?.fencePort ?? '',
    };

    return previous;
  }, initial);

const populateHostNetwork = (
  parentSequence: number,
  hostSequence: number,
  known: [string, ManifestFormikValues['netconf']['networks'][string]][],
  used: ManifestHostNetworkList = {},
  initial: ManifestFormikValues['hosts'][string]['networks'] = {},
): typeof initial =>
  known.reduce<typeof initial>((previous, entry) => {
    const [key, network] = entry;

    // Ensure the host network object keys match the netconf.networks object
    // keys for easier add or remove operations.
    previous[key] = {
      [INPUT_ID_AH_NETWORK_IP]: guessHostNetwork(
        parentSequence,
        hostSequence,
        network,
        used,
      ),
    };

    return previous;
  }, initial);

const populateHostUps = (
  known: APIManifestTemplateUps[],
  used: ManifestHostUpsList = {},
  initial: ManifestFormikValues['hosts'][string]['upses'] = {},
): typeof initial =>
  known.reduce<typeof initial>((previous, ups) => {
    const { upsName: name, upsUUID: uuid } = ups;

    previous[uuid] = {
      [INPUT_ID_AH_UPS_POWER_HOST]: used[name]?.isUsed ?? false,
    };

    return previous;
  }, initial);

const getManifestFormikInitialValues = (
  template: APIManifestTemplate,
  hosts: APIHostDetailList,
  detail?: APIManifestDetail,
): ManifestFormikValues => {
  let values: ManifestFormikValues = {
    [INPUT_ID_AI_DOMAIN]: '',
    [INPUT_ID_AI_PREFIX]: '',
    [INPUT_ID_AI_SEQUENCE]: 1,
    netconf: {
      [INPUT_ID_ANC_DNS]: '',
      [INPUT_ID_ANC_NTP]: '',
      networks: {},
    },
    hosts: {},
  };

  const knownFences = Object.values(template.fences);
  const knownUpses = Object.values(template.upses);

  if (detail) {
    values[INPUT_ID_AI_DOMAIN] = detail.domain;
    values[INPUT_ID_AI_PREFIX] = detail.prefix;
    values[INPUT_ID_AI_SEQUENCE] = detail.sequence;

    const { hostConfig, networkConfig } = detail;

    values.netconf[INPUT_ID_ANC_DNS] = networkConfig.dnsCsv;
    values.netconf[INPUT_ID_ANC_NTP] = networkConfig.ntpCsv;

    const networks = Object.values(networkConfig.networks);

    networks.forEach((network) => {
      const {
        networkGateway: gateway,
        networkMinIp: minIp,
        networkNumber: sequence,
        networkSubnetMask: subnetMask,
        networkType: type,
      } = network;

      /**
       * Identifies a node network. It doesn't match to any UUIDs in the
       * database, used only in the form to identify which to keep and/or
       * remove.
       */
      const id = uuidv4();

      values.netconf.networks[id] = {
        [INPUT_ID_AN_GATEWAY]: gateway,
        [INPUT_ID_AN_MIN_IP]: minIp,
        [INPUT_ID_AN_NETWORK_NUMBER]: sequence,
        [INPUT_ID_AN_NETWORK_TYPE]: type,
        [INPUT_ID_AN_SUBNET_MASK]: subnetMask,
      };
    });

    Object.values(hostConfig.hosts).forEach((host) => {
      const { hostNumber: sequence, ipmiIp = '' } = host;

      values.hosts[sequence] = {
        [INPUT_ID_AH_IPMI_IP]: ipmiIp,
        fences: populateHostFence(knownFences, host.fences),
        networks: populateHostNetwork(
          detail.sequence,
          sequence,
          Object.entries(values.netconf.networks),
          host.networks,
        ),
        upses: populateHostUps(knownUpses, host.upses),
      };
    });
  } else {
    // Try to guess values based on those provided during striker init.

    values[INPUT_ID_AI_DOMAIN] = template.domain;
    values[INPUT_ID_AI_PREFIX] = template.prefix;
    values[INPUT_ID_AI_SEQUENCE] = template.sequence;

    values.netconf.networks = {
      defaultbcn: {
        [INPUT_ID_AN_GATEWAY]: '',
        [INPUT_ID_AN_MIN_IP]: '10.201.0.0',
        [INPUT_ID_AN_NETWORK_NUMBER]: 1,
        [INPUT_ID_AN_NETWORK_TYPE]: 'bcn',
        [INPUT_ID_AN_SUBNET_MASK]: '255.255.0.0',
      },
      defaultifn: {
        [INPUT_ID_AN_GATEWAY]: '',
        [INPUT_ID_AN_MIN_IP]: '',
        [INPUT_ID_AN_NETWORK_NUMBER]: 1,
        [INPUT_ID_AN_NETWORK_TYPE]: 'ifn',
        [INPUT_ID_AN_SUBNET_MASK]: '',
      },
      defaultmn: {
        [INPUT_ID_AN_GATEWAY]: '',
        [INPUT_ID_AN_MIN_IP]: '10.199.0.0',
        [INPUT_ID_AN_NETWORK_NUMBER]: 1,
        [INPUT_ID_AN_NETWORK_TYPE]: 'mn',
        [INPUT_ID_AN_SUBNET_MASK]: '255.255.0.0',
      },
      defaultsn: {
        [INPUT_ID_AN_GATEWAY]: '',
        [INPUT_ID_AN_MIN_IP]: '10.101.0.0',
        [INPUT_ID_AN_NETWORK_NUMBER]: 1,
        [INPUT_ID_AN_NETWORK_TYPE]: 'sn',
        [INPUT_ID_AN_SUBNET_MASK]: '255.255.0.0',
      },
    };

    values.netconf[INPUT_ID_ANC_DNS] = '8.8.8.8,8.8.4.4';

    [1, 2].forEach((sequence) => {
      values.hosts[sequence] = {
        [INPUT_ID_AH_IPMI_IP]: '',
        fences: populateHostFence(knownFences),
        networks: populateHostNetwork(
          template.sequence,
          sequence,
          Object.entries(values.netconf.networks),
        ),
        upses: populateHostUps(knownUpses),
      };
    });

    values = guessManifestNetworks({
      hosts,
      values,
    });
  }

  return values;
};

export default getManifestFormikInitialValues;
