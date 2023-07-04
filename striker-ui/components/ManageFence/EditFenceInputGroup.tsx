import { ReactElement, useMemo } from 'react';

import CommonFenceInputGroup from './CommonFenceInputGroup';
import Spinner from '../Spinner';

const EditFenceInputGroup = <M extends Record<string, string>>({
  fenceId,
  fenceTemplate: externalFenceTemplate,
  formUtils,
  loading: isExternalLoading,
  previousFenceName,
  previousFenceParameters,
}: EditFenceInputGroupProps<M>): ReactElement => {
  const content = useMemo(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <CommonFenceInputGroup
          fenceId={fenceId}
          fenceTemplate={externalFenceTemplate}
          formUtils={formUtils}
          previousFenceName={previousFenceName}
          previousFenceParameters={previousFenceParameters}
        />
      ),
    [
      externalFenceTemplate,
      fenceId,
      formUtils,
      isExternalLoading,
      previousFenceName,
      previousFenceParameters,
    ],
  );

  return <>{content}</>;
};

export default EditFenceInputGroup;
