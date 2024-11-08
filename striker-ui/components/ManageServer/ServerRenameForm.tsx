import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import MessageGroup from '../MessageGroup';
import { buildRenameSchema } from './schemas';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerRenameForm: FC<ServerRenameFormProps> = (props) => {
  const { detail, servers } = props;

  const formikUtils = useFormikUtils<ServerRenameFormikValues>({
    initialValues: {
      name: detail.name,
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: buildRenameSchema(servers),
  });
  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      name: 'name',
    }),
    [],
  );

  return (
    <ServerFormGrid<ServerRenameFormikValues> formik={formik}>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.name}
              label="Server name"
              name={chains.name}
              onChange={handleChange}
              required
              value={formik.values.name}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ServerFormSubmit
          detail={detail}
          formDisabled={disabledSubmit}
          label="Save"
        />
      </Grid>
    </ServerFormGrid>
  );
};

export default ServerRenameForm;
