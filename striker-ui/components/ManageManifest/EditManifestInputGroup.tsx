import { ReactElement } from 'react';

import {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from './AnIdInputGroup';
import {
  INPUT_ID_ANC_DNS,
  INPUT_ID_ANC_NTP,
} from './AnNetworkConfigInputGroup';
import AddManifestInputGroup from './AddManifestInputGroup';

const EditManifestInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_AI_DOMAIN
      | typeof INPUT_ID_AI_PREFIX
      | typeof INPUT_ID_AI_SEQUENCE
      | typeof INPUT_ID_ANC_DNS
      | typeof INPUT_ID_ANC_NTP]: string;
  },
>({
  formUtils,
  knownFences,
  knownUpses,
  previous,
}: EditManifestInputGroupProps<M>): ReactElement => (
  <AddManifestInputGroup
    formUtils={formUtils}
    knownFences={knownFences}
    knownUpses={knownUpses}
    previous={previous}
  />
);

export default EditManifestInputGroup;
