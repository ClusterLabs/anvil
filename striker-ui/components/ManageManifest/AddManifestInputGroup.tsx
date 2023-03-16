import { ReactElement, useState } from 'react';

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

const DEFAULT_NETWORKS: ManifestNetworkList = {
  bcn1: {
    networkMinIp: '',
    networkNumber: 1,
    networkSubnetMask: '',
    networkType: 'bcn',
  },
  sn1: {
    networkMinIp: '',
    networkNumber: 1,
    networkSubnetMask: '',
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
  previous: { networkConfig: previousNetworkConfig = {} } = {},
}: AddManifestInputGroupProps<M>): ReactElement => {
  const { networks: previousNetworkList = DEFAULT_NETWORKS } =
    previousNetworkConfig;

  const [networkList, setNetworkList] =
    useState<ManifestNetworkList>(previousNetworkList);

  return (
    <FlexBox>
      <AnvilIdInputGroup formUtils={formUtils} />
      <AnvilNetworkConfigInputGroup
        formUtils={formUtils}
        networkList={networkList}
        previous={previousNetworkConfig}
        setNetworkList={setNetworkList}
      />
    </FlexBox>
  );
};

export default AddManifestInputGroup;
