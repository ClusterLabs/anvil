import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerNameForm: FC<ServerNameFormProps> = (props) => {
  const { detail } = props;

  const formikUtils = useFormikUtils<ServerNameFormikValues>({
    initialValues: {
      name: detail.name,
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
  });
  const { disabledSubmit, formik, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      name: 'name',
    }),
    [],
  );

  return (
    <ServerFormGrid<ServerNameFormikValues> formik={formik}>
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
        <ServerFormSubmit
          detail={detail}
          formDisabled={disabledSubmit}
          label="Save"
        />
      </Grid>
    </ServerFormGrid>
  );
};

export default ServerNameForm;
