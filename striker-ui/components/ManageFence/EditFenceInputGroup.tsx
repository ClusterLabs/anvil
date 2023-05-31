import { FC, useMemo } from 'react';

import CommonFenceInputGroup from './CommonFenceInputGroup';
import Spinner from '../Spinner';

const EditFenceInputGroup: FC<EditFenceInputGroupProps> = ({
  fenceId,
  fenceTemplate: externalFenceTemplate,
  loading: isExternalLoading,
  previousFenceName,
  previousFenceParameters,
}) => {
  const content = useMemo(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <CommonFenceInputGroup
          fenceId={fenceId}
          fenceTemplate={externalFenceTemplate}
          previousFenceName={previousFenceName}
          previousFenceParameters={previousFenceParameters}
        />
      ),
    [
      externalFenceTemplate,
      fenceId,
      isExternalLoading,
      previousFenceName,
      previousFenceParameters,
    ],
  );

  return <>{content}</>;
};

export default EditFenceInputGroup;
