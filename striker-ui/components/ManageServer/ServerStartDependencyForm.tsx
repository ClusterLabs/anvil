import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { startDependencySchema } from './schemas';
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
      after: detail.start.after || '',
      delay: String(detail.start.delay),
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: startDependencySchema,
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      after: `after`,
      delay: `delay`,
    }),
    [],
  );

  const filteredServerValues = useMemo(
    () =>
      Object.values(servers).filter(
        (server) => server.anvil.uuid === detail.anvil.uuid,
      ),
    [detail.anvil.uuid, servers],
  );

  const serverOptions = useMemo<SelectItem[]>(() => {
    const options = filteredServerValues.map<SelectItem>(({ name, uuid }) => ({
      displayValue: name,
      value: uuid,
    }));

    options.push({
      displayValue: 'Stay off',
      value: 'stay-off',
    });

    return options;
  }, [filteredServerValues]);

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
          value={formik.values.after}
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
              value={formik.values.delay}
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

export default ServerStartDependencyForm;
