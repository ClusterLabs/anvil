import { FC, ReactElement, useMemo } from 'react';

import AddUpsInputGroup from './AddUpsInputGroup';
import Spinner from '../Spinner';

const INPUT_ID_UPS_UUID = 'edit-ups-input-ups-uuid';

const EditUpsInputGroup: FC<EditUpsInputGroupProps> = ({
  loading: isExternalLoading,
  previous,
  upsTemplate,
  upsUUID,
}) => {
  const content = useMemo<ReactElement>(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <>
          <AddUpsInputGroup previous={previous} upsTemplate={upsTemplate} />
          <input hidden id={INPUT_ID_UPS_UUID} readOnly value={upsUUID} />
        </>
      ),
    [isExternalLoading, previous, upsTemplate, upsUUID],
  );

  return content;
};

export { INPUT_ID_UPS_UUID };

export default EditUpsInputGroup;
