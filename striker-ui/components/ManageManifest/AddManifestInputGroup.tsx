import { useMemo, useState } from 'react';

import AnHostConfigInputGroup from './AnHostConfigInputGroup';
import AnIdInputGroup, {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from './AnIdInputGroup';
import AnNetworkConfigInputGroup, {
  INPUT_ID_ANC_DNS,
  INPUT_ID_ANC_NTP,
} from './AnNetworkConfigInputGroup';
import FlexBox from '../FlexBox';

const DEFAULT_NETWORK_LIST: ManifestNetworkList = {
  bcn1: {
    networkMinIp: '10.201.0.0',
    networkNumber: 1,
    networkSubnetMask: '255.255.0.0',
    networkType: 'bcn',
  },
  sn1: {
    networkMinIp: '10.101.0.0',
    networkNumber: 1,
    networkSubnetMask: '255.255.0.0',
    networkType: 'sn',
  },
  ifn1: {
    networkMinIp: '',
    networkNumber: 1,
    networkSubnetMask: '',
    networkType: 'ifn',
  },
};

const AddManifestInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_AI_DOMAIN
      | typeof INPUT_ID_AI_PREFIX
      | typeof INPUT_ID_AI_SEQUENCE
      | typeof INPUT_ID_ANC_DNS
      | typeof INPUT_ID_ANC_NTP]: string;
  },
>(
  ...[props]: Parameters<React.FC<AddManifestInputGroupProps<M>>>
): ReturnType<React.FC<AddManifestInputGroupProps<M>>> => {
  const {
    formUtils,
    knownFences,
    knownUpses,
    previous: {
      hostConfig: previousHostConfig,
      networkConfig: previousNetworkConfig = {},
      ...previousAnId
    } = {},
  } = props;

  const { networks: previousNetworkList = DEFAULT_NETWORK_LIST } =
    previousNetworkConfig;

  const [anSequence, setAnSequence] = useState<number>(
    previousAnId?.sequence ?? 0,
  );

  const [networkList, setNetworkList] =
    useState<ManifestNetworkList>(previousNetworkList);

  const networkListEntries = useMemo(
    () => Object.entries(networkList),
    [networkList],
  );

  return (
    <FlexBox>
      <AnIdInputGroup
        formUtils={formUtils}
        onSequenceChange={(event) => {
          const {
            target: { value },
          } = event;

          setAnSequence(Number(value));
        }}
        previous={previousAnId}
      />
      <AnNetworkConfigInputGroup
        formUtils={formUtils}
        networkListEntries={networkListEntries}
        previous={previousNetworkConfig}
        setNetworkList={setNetworkList}
      />
      <AnHostConfigInputGroup
        anSequence={anSequence}
        formUtils={formUtils}
        knownFences={knownFences}
        knownUpses={knownUpses}
        networkListEntries={networkListEntries}
        previous={previousHostConfig}
      />
    </FlexBox>
  );
};

export default AddManifestInputGroup;
