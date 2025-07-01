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

const getHostFences = (
  knownFences: APIManifestTemplateFenceList,
  fences: ManifestFormikValues['hosts'][string]['fences'],
): Exclude<
  APIBuildManifestRequestBody['hostConfig']['hosts'][string]['fences'],
  undefined
> =>
  Object.entries(fences).reduce<ReturnType<typeof getHostFences>>(
    (previous, entry) => {
      const [fenceUuid, fence] = entry;

      const { [INPUT_ID_AH_FENCE_PORT]: port = '' } = fence;

      const { [fenceUuid]: known } = knownFences;

      previous[fenceUuid] = {
        fenceName: known.fenceName,
        fencePort: port,
      };

      return previous;
    },
    {},
  );

const getHostNetworks = (
  createdNetworks: ManifestFormikValues['netconf']['networks'],
  networks: ManifestFormikValues['hosts'][string]['networks'],
): Exclude<
  APIBuildManifestRequestBody['hostConfig']['hosts'][string]['networks'],
  undefined
> =>
  Object.entries(networks).reduce<ReturnType<typeof getHostNetworks>>(
    (previous, entry) => {
      // `networkId` can be an UI-generated UUID or a phrase starting with 'default'
      const [networkId, network] = entry;

      const { [INPUT_ID_AH_NETWORK_IP]: ip } = network;

      const { [networkId]: created } = createdNetworks;

      const {
        [INPUT_ID_AN_NETWORK_NUMBER]: sequence = 0,
        [INPUT_ID_AN_NETWORK_TYPE]: type = '',
      } = created;

      const key = `${type}${sequence}`;

      previous[key] = {
        networkIp: ip,
        networkNumber: sequence,
        networkType: type,
      };

      return previous;
    },
    {},
  );

const getHostUpses = (
  knownUpses: APIManifestTemplateUpsList,
  upses: ManifestFormikValues['hosts'][string]['upses'],
): Exclude<
  APIBuildManifestRequestBody['hostConfig']['hosts'][string]['upses'],
  undefined
> =>
  Object.entries(upses).reduce<ReturnType<typeof getHostUpses>>(
    (previous, entry) => {
      const [upsUuid, ups] = entry;

      const { [INPUT_ID_AH_UPS_POWER_HOST]: power = false } = ups;

      const { [upsUuid]: known } = knownUpses;

      previous[upsUuid] = {
        isUsed: power,
        upsName: known.upsName,
      };

      return previous;
    },
    {},
  );

const getHosts = (
  template: APIManifestTemplate,
  values: ManifestFormikValues,
): APIBuildManifestRequestBody['hostConfig']['hosts'] =>
  Object.entries(values.hosts).reduce<ReturnType<typeof getHosts>>(
    (previous, entry) => {
      const [hostSequence, host] = entry;

      const { [INPUT_ID_AH_IPMI_IP]: ipmiIp, fences, networks, upses } = host;

      const type = 'node';

      const key = `${type}${hostSequence}`;

      previous[key] = {
        fences: getHostFences(template.fences, fences),
        hostNumber: Number(hostSequence),
        hostType: type,
        ipmiIp,
        networks: getHostNetworks(values.netconf.networks, networks),
        upses: getHostUpses(template.upses, upses),
      };

      return previous;
    },
    {},
  );

const getNetworks = (
  networks: ManifestFormikValues['netconf']['networks'],
): APIBuildManifestRequestBody['networkConfig']['networks'] =>
  Object.values(networks).reduce<ReturnType<typeof getNetworks>>(
    (previous, network) => {
      const {
        [INPUT_ID_AN_GATEWAY]: gateway,
        [INPUT_ID_AN_MIN_IP]: minIp = '',
        [INPUT_ID_AN_NETWORK_NUMBER]: sequence = 0,
        [INPUT_ID_AN_NETWORK_TYPE]: type = '',
        [INPUT_ID_AN_SUBNET_MASK]: subnetMask = '',
      } = network;

      const key = `${type}${sequence}`;

      previous[key] = {
        networkGateway: gateway,
        networkMinIp: minIp,
        networkNumber: sequence,
        networkSubnetMask: subnetMask,
        networkType: type,
      };

      return previous;
    },
    {},
  );

const getManifestRequestBody = (
  template: APIManifestTemplate,

  values: ManifestFormikValues,
): APIBuildManifestRequestBody => {
  const {
    [INPUT_ID_AI_DOMAIN]: domain,
    [INPUT_ID_AI_PREFIX]: prefix,
    [INPUT_ID_AI_SEQUENCE]: sequence,
    netconf,
  } = values;

  const {
    [INPUT_ID_ANC_DNS]: dnsCsv = '',
    [INPUT_ID_ANC_NTP]: ntpCsv = '',
    networks,
  } = netconf;

  const body: APIBuildManifestRequestBody = {
    domain,
    hostConfig: {
      hosts: getHosts(template, values),
    },
    networkConfig: {
      dnsCsv,
      networks: getNetworks(networks),
      ntpCsv,
    },
    prefix,
    sequence,
  };

  return body;
};

export default getManifestRequestBody;
