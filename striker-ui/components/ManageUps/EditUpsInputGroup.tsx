import { ReactElement, useMemo } from 'react';

import AddUpsInputGroup, { INPUT_ID_UPS_TYPE } from './AddUpsInputGroup';
import { INPUT_ID_UPS_IP, INPUT_ID_UPS_NAME } from './CommonUpsInputGroup';
import Spinner from '../Spinner';

const INPUT_ID_UPS_UUID = 'edit-ups-input-ups-uuid';

const EditUpsInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_UPS_IP
      | typeof INPUT_ID_UPS_NAME
      | typeof INPUT_ID_UPS_TYPE]: string;
  },
>({
  formUtils,
  loading: isExternalLoading,
  previous,
  upsTemplate,
  upsUUID,
}: EditUpsInputGroupProps<M>): ReactElement => {
  const content = useMemo<ReactElement>(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <>
          <AddUpsInputGroup
            formUtils={formUtils}
            previous={previous}
            upsTemplate={upsTemplate}
          />
          <input hidden id={INPUT_ID_UPS_UUID} readOnly value={upsUUID} />
        </>
      ),
    [formUtils, isExternalLoading, previous, upsTemplate, upsUUID],
  );

  return content;
};

export { INPUT_ID_UPS_UUID };

export default EditUpsInputGroup;
