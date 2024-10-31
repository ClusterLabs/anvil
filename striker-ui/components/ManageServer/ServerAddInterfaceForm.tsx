import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import Autocomplete from '../Autocomplete';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { buildAddInterfaceSchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerAddInterfaceForm: FC<ServerAddInterfaceFormProps> = (props) => {
  const { detail } = props;

  const formikUtils = useFormikUtils<ServerInterfaceFormikValues>({
    initialValues: {
      bridge: '',
      mac: '',
      model: null,
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: buildAddInterfaceSchema(detail),
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      bridge: 'bridge',
      mac: 'mac',
      model: 'model',
    }),
    [],
  );

  const bridgeOptions = useMemo(() => {
    const bridges = Object.values(detail.host.bridges);

    return bridges.map<SelectItem>((bridge) => {
      const { name, uuid } = bridge;

      return {
        displayValue: name,
        value: uuid,
      };
    });
  }, [detail.host.bridges]);

  return (
    <ServerFormGrid<ServerInterfaceFormikValues> formik={formik}>
      <Grid item xs={1}>
        <SelectWithLabel
          id={chains.bridge}
          label="Bridge"
          name={chains.bridge}
          onChange={formik.handleChange}
          required
          selectItems={bridgeOptions}
          value={formik.values.bridge}
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.mac}
              label="Mac address"
              name={chains.mac}
              onChange={handleChange}
              value={formik.values.mac}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <Autocomplete
          autoHighlight
          id={chains.model}
          label="Model"
          noOptionsText="No matching model"
          onChange={(event, value) => {
            formik.setFieldValue(chains.model, value, true);
          }}
          openOnFocus
          options={detail.libvirt.nicModels}
          value={formik.values.model}
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

export default ServerAddInterfaceForm;
