import { ReactElement, useMemo, useState } from 'react';

import AnvilHostConfigInputGroup from './AnvilHostConfigInputGroup';
import AnvilIdInputGroup, {
  INPUT_ID_ANVIL_ID_DOMAIN,
  INPUT_ID_ANVIL_ID_PREFIX,
  INPUT_ID_ANVIL_ID_SEQUENCE,
} from './AnvilIdInputGroup';
import AnvilNetworkConfigInputGroup, {
  INPUT_ID_ANVIL_NETWORK_CONFIG_DNS,
  INPUT_ID_ANVIL_NETWORK_CONFIG_MTU,
  INPUT_ID_ANVIL_NETWORK_CONFIG_NTP,
} from './AnvilNetworkConfigInputGroup';
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
      | typeof INPUT_ID_ANVIL_ID_DOMAIN
      | typeof INPUT_ID_ANVIL_ID_PREFIX
      | typeof INPUT_ID_ANVIL_ID_SEQUENCE
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_DNS
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_MTU
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_NTP]: string;
  },
>({
  formUtils,
  knownFences,
  knownUpses,
  previous: {
    hostConfig: previousHostConfig,
    networkConfig: previousNetworkConfig = {},
    ...previousAnId
  } = {},
}: AddManifestInputGroupProps<M>): ReactElement => {
  const { networks: previousNetworkList = DEFAULT_NETWORK_LIST } =
    previousNetworkConfig;

  const [networkList, setNetworkList] =
    useState<ManifestNetworkList>(previousNetworkList);

  const networkListEntries = useMemo(
    () => Object.entries(networkList),
    [networkList],
  );

  return (
    <FlexBox>
      <AnvilIdInputGroup formUtils={formUtils} previous={previousAnId} />
      <AnvilNetworkConfigInputGroup
        formUtils={formUtils}
        networkListEntries={networkListEntries}
        previous={previousNetworkConfig}
        setNetworkList={setNetworkList}
      />
      <AnvilHostConfigInputGroup
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
