import Grid from '@mui/material/Grid';
import { useCallback, useMemo, useRef } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import buildInitRequestBody from '../../lib/buildInitRequestBody';
import handleAPIError from '../../lib/handleAPIError';
import { HostNetInitInputGroup } from '../HostNetInit';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import pad from '../../lib/pad';
import strikerInitSchema from './strikerInitSchema';
import StrikerInitSummary from './StrikerInitSummary';
import toHostNetList from '../../lib/toHostNetList';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const buildFormikInitialValues = (
  detail?: APIHostDetail,
): StrikerInitFormikValues => {
  let domainName = '';
  let hostName = '';
  let hostNumber = '';

  let dns = '';
  let gateway = '';
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
  };
  let ntp = '';

  let organizationName = '';
  let organizationPrefix = '';

  if (detail) {
    ({
      domain: domainName = '',
      organization: organizationName = '',
      prefix: organizationPrefix = '',
    } = detail.variables);

    hostName = detail.name;

    const { sequence } = detail.variables;

    hostNumber = sequence ? String(sequence) : '';

    ({ dns = '', gateway = '', ntp = '' } = detail.netconf);

    const { networks: nets = {} } = detail.netconf;

    networks = toHostNetList(nets);
  }

  return {
    adminPassword: '',
    confirmAdminPassword: '',
    domainName,
    hostName,
    hostNumber,
    networkInit: {
      dns,
      gateway,
      networks,
      ntp,
    },
    organizationName,
    organizationPrefix,
  };
};

const guessHostName = (
  orgPrefix: string,
  hostNumber: string,
  domainName: string,
): string =>
  [orgPrefix, hostNumber, domainName].every((value) => value.length > 0)
    ? `${orgPrefix}-striker${pad(hostNumber)}.${domainName}`
    : '';

const guessOrgPrefix = (orgName: string, max = 5): string => {
  const words: string[] = orgName
    .split(/\s+/)
    .filter((word) => !/^(?:and|of)$/.test(word))
    .slice(0, max);

  let result = '';

  if (words.length > 1) {
    result = words
      .map((word) => word.substring(0, 1).toLocaleLowerCase())
      .join('');
  } else if (words.length === 1) {
    result = words[0].substring(0, max).toLocaleLowerCase();
  }

  return result;
};

const StrikerInitForm: React.FC<StrikerInitFormProps> = (props) => {
  const { detail, ipRef, onSubmitSuccess, tools } = props;

  const ifaces = useRef<APINetworkInterfaceOverviewList | null>(null);

  const formikUtils = useFormikUtils<StrikerInitFormikValues>({
    initialValues: buildFormikInitialValues(detail),
    onSubmit: (values, { setSubmitting }) => {
      const requestBody = buildInitRequestBody(values, ifaces.current);

      if (ipRef) {
        requestBody.networks.forEach((network) => {
          const { ipAddress, sequence, type } = network;

          if (`${type}${sequence}` !== requestBody.gatewayInterface) {
            return;
          }

          ipRef.current = ipAddress;
        });
      }

      tools.confirm.prepare({
        actionProceedText: 'Initialize',
        content: ifaces.current && (
          <StrikerInitSummary
            gatewayIface={requestBody.gatewayInterface}
            ifaces={ifaces.current}
            values={values}
          />
        ),
        onCancelAppend: () => setSubmitting(false),
        onProceedAppend: () => {
          tools.confirm.loading(true);

          api
            .put('/init', requestBody)
            .then((response) => {
              onSubmitSuccess?.call(null, response.data);

              tools.confirm.finish('Success', {
                children: (
                  <>Successfully registered striker initialization job.</>
                ),
              });
            })
            .catch((error) => {
              const emsg = handleAPIError(error);

              emsg.children = (
                <>
                  Failed to register striker initialization job. {emsg.children}
                </>
              );

              tools.confirm.finish('Error', emsg);

              setSubmitting(false);
            });
        },
        titleText: `Initialize ${values.hostName} with the following?`,
      });

      tools.confirm.open();
    },
    validationSchema: strikerInitSchema,
  });

  const {
    disabledSubmit,
    formik,
    formikErrors,
    getFieldChanged,
    handleChange,
  } = formikUtils;

  const adminPasswordChain = useMemo(() => `adminPassword`, []);
  const confirmAdminPasswordChain = useMemo(() => `confirmAdminPassword`, []);
  const domainNameChain = useMemo(() => `domainName`, []);
  const hostNameChain = useMemo(() => `hostName`, []);
  const hostNumberChain = useMemo(() => `hostNumber`, []);
  const orgNameChain = useMemo(() => `organizationName`, []);
  const orgPrefixChain = useMemo(() => `organizationPrefix`, []);

  const buildHostNameGuesser = useCallback(
    (key: string) =>
      (event: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        if (getFieldChanged(hostNameChain)) return;

        const {
          target: { value },
        } = event;

        let {
          values: { domainName, hostNumber, organizationPrefix },
        } = formik;

        switch (key) {
          case domainNameChain:
            domainName = value;
            break;
          case hostNumberChain:
            hostNumber = value;
            break;
          case orgPrefixChain:
            organizationPrefix = value;
            break;
          default:
            break;
        }

        const guess = guessHostName(organizationPrefix, hostNumber, domainName);

        formik.setFieldValue(hostNameChain, guess);
      },
    [
      domainNameChain,
      formik,
      getFieldChanged,
      hostNameChain,
      hostNumberChain,
      orgPrefixChain,
    ],
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
        <Grid columns={2} container spacing="1em">
          <Grid item width="100%">
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={orgNameChain}
                  label="Organization Name"
                  name={orgNameChain}
                  onBlur={(event) => {
                    if (getFieldChanged(orgPrefixChain)) {
                      return;
                    }

                    const {
                      target: { value },
                    } = event;

                    const guess = guessOrgPrefix(value);

                    formik.setFieldValue(orgPrefixChain, guess);
                  }}
                  onChange={handleChange}
                  required
                  value={formik.values.organizationName}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  baseInputProps={{ maxLength: 5 }}
                  id={orgPrefixChain}
                  label="Prefix"
                  name={orgPrefixChain}
                  onBlur={buildHostNameGuesser(orgPrefixChain)}
                  onChange={handleChange}
                  required
                  value={formik.values.organizationPrefix}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={hostNumberChain}
                  label="Striker #"
                  name={hostNumberChain}
                  onBlur={buildHostNameGuesser(hostNumberChain)}
                  onChange={handleChange}
                  required
                  value={formik.values.hostNumber}
                />
              }
            />
          </Grid>
        </Grid>
      </Grid>
      <Grid item xs={1}>
        <Grid columns={1} container spacing="1em">
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={domainNameChain}
                  label="Domain name"
                  name={domainNameChain}
                  onBlur={buildHostNameGuesser(domainNameChain)}
                  onChange={handleChange}
                  required
                  value={formik.values.domainName}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={hostNameChain}
                  label="Host name"
                  name={hostNameChain}
                  onChange={handleChange}
                  required
                  value={formik.values.hostName}
                />
              }
            />
          </Grid>
        </Grid>
      </Grid>
      <Grid item xs={1} sm={2} md={1}>
        <Grid columns={{ xs: 1, sm: 2, md: 1 }} container spacing="1em">
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={adminPasswordChain}
                  label="Admin password"
                  name={adminPasswordChain}
                  onChange={handleChange}
                  required
                  type={INPUT_TYPES.password}
                  value={formik.values.adminPassword}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={confirmAdminPasswordChain}
                  label="Confirm admin password"
                  name={confirmAdminPasswordChain}
                  onChange={handleChange}
                  required
                  type={INPUT_TYPES.password}
                  value={formik.values.confirmAdminPassword}
                />
              }
            />
          </Grid>
        </Grid>
      </Grid>
      <Grid item width="100%">
        <HostNetInitInputGroup
          formikUtils={formikUtils}
          host={{
            parentSequence: NaN,
            sequence: Number(formik.values.hostNumber),
            type: 'striker',
            uuid: 'local',
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
              children: 'Initialize',
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default StrikerInitForm;
