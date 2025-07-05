import { v4 as uuidv4 } from 'uuid';

import { ManifestFormikValues } from './schemas/buildManifestSchema';

import {
  INPUT_ID_AH_NETWORK_IP,
  INPUT_ID_AN_GATEWAY,
  INPUT_ID_AN_MIN_IP,
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
  INPUT_ID_AN_SUBNET_MASK,
} from './inputIds';

const addNetwork = (values: ManifestFormikValues): typeof values => {
  const existingNetworks = Object.values(values.netconf.networks);

  const hasMn = existingNetworks.some(
    (network) => network[INPUT_ID_AN_NETWORK_TYPE] === 'mn',
  );

  let nyuNetwork: (typeof values)['netconf']['networks'][string];

  if (hasMn) {
    const maxSequence = existingNetworks.reduce<number>((previous, network) => {
      const {
        [INPUT_ID_AN_NETWORK_NUMBER]: sequence = 0,
        [INPUT_ID_AN_NETWORK_TYPE]: type,
      } = network;

      return type === 'ifn' ? Math.max(previous, sequence) : previous;
    }, 0);

    nyuNetwork = {
      [INPUT_ID_AN_GATEWAY]: '',
      [INPUT_ID_AN_MIN_IP]: '',
      [INPUT_ID_AN_NETWORK_NUMBER]: maxSequence + 1,
      [INPUT_ID_AN_NETWORK_TYPE]: 'ifn',
      [INPUT_ID_AN_SUBNET_MASK]: '',
    };
  } else {
    nyuNetwork = {
      [INPUT_ID_AN_GATEWAY]: '',
      [INPUT_ID_AN_MIN_IP]: '10.199.0.0',
      [INPUT_ID_AN_NETWORK_NUMBER]: 1,
      [INPUT_ID_AN_NETWORK_TYPE]: 'mn',
      [INPUT_ID_AN_SUBNET_MASK]: '255.255.0.0',
    };
  }

  const hostNetwork: (typeof values)['hosts'][string]['networks'][string] = {
    [INPUT_ID_AH_NETWORK_IP]: '',
  };

  const networkUuid = uuidv4();

  const result: typeof values = { ...values };

  result.netconf.networks = {
    ...result.netconf.networks,
    [networkUuid]: nyuNetwork,
  };

  Object.keys(result.hosts).forEach((hostSequence) => {
    const { [hostSequence]: host } = result.hosts;

    host.networks = {
      ...host.networks,
      [networkUuid]: hostNetwork,
    };
  });

  return result;
};

export default addNetwork;
