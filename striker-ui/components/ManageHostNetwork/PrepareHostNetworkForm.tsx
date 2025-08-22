import Grid from '@mui/material/Grid';
import isEmpty from 'lodash/isEmpty';
import { useMemo, useRef } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import buildInitRequestBody from '../../lib/buildInitRequestBody';
import handleAPIError from '../../lib/handleAPIError';
import { HostNetInitInputGroup } from '../HostNetInit';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import prepareHostNetworkSchema from './prepareHostNetworkSchema';
import PrepareHostNetworkSummary from './PrepareHostNetworkSummary';
import SwitchWithLabel from '../SwitchWithLabel';
import toHostNetList from '../../lib/toHostNetList';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const buildFormikInitialValues = (
  detail: APIHostDetail,
): PrepareHostNetworkFormikValues => {
  const { dns = '', gateway = '', networks: nets, ntp = '' } = detail.netconf;

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
    defaultmn: {
      interfaces: ['', ''],
      ip: '',
      sequence: '1',
      subnetMask: '',
      type: 'mn',
    },
  };

  if (!isEmpty(nets)) {
    networks = toHostNetList(nets);
  }

  const { name: hostName } = detail;

  return {
    hostName,
    mini: false,
    networkInit: {
      dns,
      gateway,
      networks,
      ntp,
    },
  };
};

const PrepareHostNetworkForm: React.FC<PrepareHostNetworkFormProps> = (
  props,
) => {
  const { detail, tools, uuid } = props;

  const ifaces = useRef<APINetworkInterfaceOverviewList | null>(null);

  const formikUtils = useFormikUtils<PrepareHostNetworkFormikValues>(
    {
      initialValues: buildFormikInitialValues(detail),
      onSubmit: (values, { setSubmitting }) => {
        const requestBody = buildInitRequestBody(values, ifaces.current);

        tools.confirm.prepare({
          actionProceedText: 'Prepare network',
          content: ifaces.current && (
            <PrepareHostNetworkSummary
              gatewayIface={requestBody.gatewayInterface}
              ifaces={ifaces.current}
              values={values}
            />
          ),
          onCancelAppend: () => setSubmitting(false),
          onProceedAppend: () => {
            tools.confirm.loading(true);

            api
              .put(`/host/${detail.uuid}?handler=subnode-network`, requestBody)
              .then(() => {
                tools.confirm.finish('Success', {
                  children: (
                    <>Successfully started network config on {detail.short}</>
                  ),
                });
              })
              .catch((error) => {
                const emsg = handleAPIError(error);

                emsg.children = (
                  <>
                    Failed to prepare network on {detail.short}. {emsg.children}
                  </>
                );

                tools.confirm.finish('Error', emsg);

                setSubmitting(false);
              });
          },
          titleText: `Prepare network on ${detail.short} with the following?`,
        });

        tools.confirm.open();
      },
      validationSchema: prepareHostNetworkSchema,
    },
    {
      allowClean: true,
    },
  );

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const hostType = useMemo(
    () => detail.type.replace('node', 'subnode'),
    [detail.type],
  );

  const { parentSequence, sequence } = useMemo(() => {
    const numbers = detail.short.replace(/^.*a(\d+).*(?:n|dr)(\d+)$/, '$1,$2');

    const [parentSeq, seq] = numbers.split(',', 2);

    return {
      parentSequence: Number(parentSeq),
      sequence: Number(seq),
    };
  }, [detail.short]);

  const chains = useMemo(
    () => ({
      hostName: `hostName`,
      mini: `mini`,
      networks: `networkInit.networks`,
    }),
    [],
  );

  return (
    <Grid
      columns={{ xs: 1, sm: 2, md: 3, lg: 4 }}
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
      <Grid display={{ xs: 'none', md: 'initial' }} flexGrow={1} item />
      <Grid item xs={1}>
        <SwitchWithLabel
          id={chains.mini}
          label="Minimal config"
          name={chains.mini}
          onChange={(event, checked) => {
            if (checked) {
              const { defaultbcn } = formik.values.networkInit.networks;

              formik.setFieldValue(chains.networks, { defaultbcn }, true);
            } else {
              formik.resetForm();
            }

            formik.handleChange(event);
          }}
          checked={formik.values.mini}
        />
      </Grid>
      <Grid item width="100%">
        <HostNetInitInputGroup
          formikUtils={formikUtils}
          host={{
            parentSequence,
            sequence,
            type: hostType,
            uuid,
          }}
          onFetchSuccess={(data) => {
            ifaces.current = data;
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
