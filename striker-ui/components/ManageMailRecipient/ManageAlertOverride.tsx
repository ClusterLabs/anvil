import { FC } from 'react';
import { v4 as uuidv4 } from 'uuid';

import AlertOverrideInputGroup from './AlertOverrideInputGroup';
import List from '../List';
import useChecklist from '../../hooks/useChecklist';

const ManageAlertOverride: FC<ManageAlertOverrideProps> = (props) => {
  const {
    alertOverrideTargetOptions,
    formikUtils,
    mailRecipientUuid: mrUuid,
  } = props;

  const { formik } = formikUtils;
  const {
    values: { [mrUuid]: mailRecipient },
  } = formik;
  const { alertOverrides } = mailRecipient;

  const { hasChecks } = useChecklist(alertOverrides);

  return (
    <List
      allowAddItem
      disableDelete={!hasChecks}
      edit
      header="Alert override rules"
      listEmpty="No alert overrides(s)"
      listItems={alertOverrides}
      onAdd={() => {
        const aoUuid = uuidv4();

        formik.setValues((previous) => {
          const current = { ...previous };

          current[mrUuid].alertOverrides[aoUuid] = {
            level: 2,
            target: null,
            uuid: aoUuid,
          };

          return current;
        });
      }}
      renderListItem={(uuid) => (
        <AlertOverrideInputGroup
          alertOverrideTargetOptions={alertOverrideTargetOptions}
          alertOverrideUuid={uuid}
          formikUtils={formikUtils}
          mailRecipientUuid={mrUuid}
        />
      )}
    />
  );
};

export default ManageAlertOverride;
