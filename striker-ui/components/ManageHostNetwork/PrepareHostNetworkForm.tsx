import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import { HostNetInitInputGroup } from '../HostNetInit';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';
import SwitchWithLabel from '../SwitchWithLabel';
import prepareHostNetworkSchema from './prepareHostNetworkSchema';
import toHostNetList from '../../lib/toHostNetList';

const buildFormikInitialValues = (
  detail: APIHostDetail,
): PrepareHostNetworkFormikValues => {
  const { dns = '', gateway = '', hostName = '', networks: nets } = detail;

  let networks: Record<string, HostNetFormikValues> = {
    defaultbcn: {
      interfaces: ['', ''],
      ip: '',
      sequence: '1',
      subnetMask: '',
      type: 'bcn',
    },
    defaultifn: {
      interfaces: ['', ''],
      ip: '',
      sequence: '1',
      subnetMask: '',
      type: 'ifn',
    },
    defaultsn: {
      interfaces: ['', ''],
      ip: '',
      sequence: '1',
      subnetMask: '',
      type: 'sn',
    },
  };

  if (nets) {
    networks = toHostNetList(nets);
  }

  return {
    hostName,
    mini: false,
    networkInit: {
      dns,
      gateway,
      networks,
    },
  };
};

const PrepareHostNetworkForm: FC<PrepareHostNetworkFormProps> = (props) => {
  const { detail, uuid } = props;

  const formikUtils = useFormikUtils<PrepareHostNetworkFormikValues>({
    initialValues: buildFormikInitialValues(detail),
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: prepareHostNetworkSchema,
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const sequence = useMemo(() => {
    const trailing = detail.shortHostName.replace(/^.*(\d+)$/, '$1');

    return Number(trailing);
  }, [detail.shortHostName]);

  const chains = useMemo(
    () => ({
      mini: `mini`,
      hostName: `hostName`,
    }),
    [],
  );

  return (
    <Grid
      columns={{ xs: 1, sm: 2, md: 3 }}
      component="form"
      container
      onSubmit={(event) => {
        event.preventDefault();

        formik.handleSubmit(event);
      }}
      spacing="1em"
    >
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.hostName}
              label="Host name"
              name={chains.hostName}
              onChange={handleChange}
              required
              value={formik.values.hostName}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <SwitchWithLabel
          id={chains.mini}
          label="Minimal config"
          name={chains.mini}
          onChange={formik.handleChange}
          checked={formik.values.mini}
        />
      </Grid>
      <Grid item width="100%">
        <HostNetInitInputGroup
          formikUtils={formikUtils}
          host={{
            sequence,
            type: 'subnode',
            uuid,
          }}
        />
      </Grid>
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ActionGroup
          actions={[
            {
              background: 'blue',
              children: 'Prepare network',
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default PrepareHostNetworkForm;
