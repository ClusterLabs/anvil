import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import Autocomplete from '../Autocomplete';
import handleFormSubmit from './handleFormSubmit';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { buildAddInterfaceSchema } from './schemas';
import SelectWithLabel from '../SelectWithLabel';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const defaults = {
  mac: 'auto',
  model: 'e1000e',
};

const ServerAddInterfaceForm: FC<ServerAddInterfaceFormProps> = (props) => {
  const { detail, tools } = props;

  const formikUtils = useFormikUtils<ServerInterfaceFormikValues>({
    initialValues: {
      bridge: '',
      mac: '',
      model: defaults.model,
    },
    onSubmit: (values, helpers) => {
      handleFormSubmit(
        values,
        helpers,
        tools,
        () => `/server/${detail.uuid}/add-interface`,
        () => `Add interface?`,
        {
          buildSummary: (v) => {
            const clone = { ...v };

            clone.bridge = detail.host.bridges[v.bridge].name;

            if (!clone.mac) {
              clone.mac = defaults.mac;
            }

            return clone;
          },
          buildRequestBody: (v, s) => {
            const result: Record<string, string> = {};

            if (s?.bridge) {
              result.bridge = s.bridge;
            }

            if (s?.mac && s.mac !== defaults.mac) {
              result.mac = s.mac;
            }

            if (s?.model && s.model !== defaults.model) {
              result.model = s.model;
            }

            return result;
          },
        },
      );
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
              inputLabelProps={{
                shrink: true,
              }}
              inputProps={{
                notched: true,
                placeholder: 'Auto generated',
              }}
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
