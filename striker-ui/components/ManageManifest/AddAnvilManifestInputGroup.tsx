import { ReactElement } from 'react';

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

const AddAnvilManifestInputGroup = <
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
}: AddAnvilInputGroupProps<M>): ReactElement => (
  <FlexBox>
    <AnvilIdInputGroup formUtils={formUtils} />
    <AnvilNetworkConfigInputGroup formUtils={formUtils} />
  </FlexBox>
);

export default AddAnvilManifestInputGroup;
