import { ManifestFormikValues } from './schemas/buildManifestSchema';

import {
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
} from './inputIds';

const guessHostNetwork = (
  parentSequence: number,
  hostSequence: number,
  known: ManifestFormikValues['netconf']['networks'][string],
  used: ManifestHostNetworkList = {},
) => {
  const {
    [INPUT_ID_AN_NETWORK_NUMBER]: sequence = 0,
    [INPUT_ID_AN_NETWORK_TYPE]: type,
  } = known;

  const id = `${type}${sequence}`;

  const o3 = 10 + 2 * (parentSequence - 1);
  const o4 = hostSequence;

  let o2 = 0;

  let fallback: string;

  switch (type) {
    case 'bcn':
      o2 = 200 + sequence;
      fallback = `10.${o2}.${o3}.${o4}`;
      break;
    case 'mn':
      o2 = 199;
      fallback = `10.${o2}.${o3}.${o4}`;
      break;
    case 'sn':
      o2 = 100 + sequence;
      fallback = `10.${o2}.${o3}.${o4}`;
      break;
    default:
      fallback = '';
  }

  return used[id]?.networkIp ?? fallback;
};

export default guessHostNetwork;
