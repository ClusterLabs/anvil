import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerStartDependencyForm: FC<ServerStartDependencyFormProps> = (
  props,
) => {
  const { detail, servers } = props;

  const formikUtils = useFormikUtils<ServerStartDependencyFormikValues>({
    initialValues: {
      start: {
        after: detail.start.after || '',
        delay: detail.start.delay,
      },
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
  });

  const { disabledSubmit, formik, handleChange } = formikUtils;

  const chains = useMemo(() => {
    const base = 'start';

    return {
      after: `${base}.after`,
      delay: `${base}.delay`,
    };
  }, []);

  const serverValues = useMemo(() => Object.values(servers), [servers]);

  const serverOptions = useMemo<SelectItem[]>(() => {
    const options = serverValues.map<SelectItem>(({ name, uuid }) => ({
      displayValue: name,
      value: uuid,
    }));

    options.push({
      displayValue: 'Stay off',
      value: 'stay-off',
    });

    return options;
  }, [serverValues]);

  return (
    <ServerFormGrid<ServerStartDependencyFormikValues> formik={formik}>
      <Grid item xs={1}>
        <SelectWithLabel
          id={chains.after}
          label="Start after"
          name={chains.after}
          onChange={formik.handleChange}
          selectItems={serverOptions}
          selectProps={{
            onClearIndicatorClick: () => {
              formik.setFieldValue(chains.after, '', true);
            },
          }}
          value={formik.values.start.after}
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.delay}
              label="Delay (seconds)"
              name={chains.delay}
              onChange={handleChange}
              value={formik.values.start.delay}
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

export default ServerStartDependencyForm;
