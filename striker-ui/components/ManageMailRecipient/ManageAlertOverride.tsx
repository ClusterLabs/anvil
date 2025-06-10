import { v4 as uuidv4 } from 'uuid';

import AlertOverrideInputGroup from './AlertOverrideInputGroup';
import List from '../List';

const ManageAlertOverride: React.FC<ManageAlertOverrideProps> = (props) => {
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

  return (
    <List
      allowAddItem
      edit
      header="Alert override rules"
      listEmpty="No alert overrides(s)"
      listItems={alertOverrides}
      onAdd={() => {
        /**
         * This is **not** the same as an alert override UUID because 1 alert
         * override formik value can reference _n_ alert override rules, where
         * _n_ is the number of subnodes per node. */
        const valueId = uuidv4();

        formik.setValues((previous: MailRecipientFormikValues) => {
          const shallow = { ...previous };
          const { [mrUuid]: mr } = shallow;

          mr.alertOverrides = {
            ...mr.alertOverrides,
            [valueId]: { level: 2, target: null },
          };

          return shallow;
        });
      }}
      renderListItem={(valueId, value: AlertOverrideFormikAlertOverride) =>
        !value.remove && (
          <AlertOverrideInputGroup
            alertOverrideTargetOptions={alertOverrideTargetOptions}
            alertOverrideValueId={valueId}
            formikUtils={formikUtils}
            mailRecipientUuid={mrUuid}
          />
        )
      }
    />
  );
};

export default ManageAlertOverride;
