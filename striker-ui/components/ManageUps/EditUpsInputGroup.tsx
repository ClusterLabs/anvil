import { FC, ReactElement, useMemo } from 'react';

import CommonUpsInputGroup from './CommonUpsInputGroup';
import Spinner from '../Spinner';

const EditUpsInputGroup: FC<EditUpsInputGroupProps> = ({
  loading: isExternalLoading,
  previous,
  upsUUID,
}) => {
  const content = useMemo<ReactElement>(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <>
          <CommonUpsInputGroup previous={previous} />
          <input hidden id="edit-ups-input-ups-uuid" readOnly value={upsUUID} />
        </>
      ),
    [isExternalLoading, previous, upsUUID],
  );

  return content;
};

export default EditUpsInputGroup;
