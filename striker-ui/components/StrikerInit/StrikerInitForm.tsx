import { Grid } from '@mui/material';
import { FC, useCallback, useMemo, useRef } from 'react';

import useFormikUtils from '../../hooks/useFormikUtils';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';
import MessageGroup from '../MessageGroup';
import strikerInitSchema from './strikerInitSchema';
import ActionGroup from '../ActionGroup';
import UncontrolledInput from '../UncontrolledInput';
import pad from '../../lib/pad';

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

const StrikerInitForm: FC = () => {
  const orgPrefixInputRef =
    useRef<UncontrolledInputForwardedRefContent<keyof MapToInputType>>(null);

  const hostNameInputRef =
    useRef<UncontrolledInputForwardedRefContent<keyof MapToInputType>>(null);

  const {
    disabledSubmit,
    formik,
    formikErrors,
    getFieldChanged,
    handleChange,
  } = useFormikUtils<StrikerInitFormikValues>({
    initialValues: {
      adminPassword: '',
      confirmAdminPassword: '',
      domainName: '',
      hostName: '',
      hostNumber: '',
      organizationName: '',
      organizationPrefix: '',
    },
    onSubmit: (values, { setSubmitting }) => {
      setSubmitting(false);
    },
    validationSchema: strikerInitSchema,
  });

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

        hostNameInputRef.current?.set(guess);

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
                    if (getFieldChanged(orgPrefixChain)) return;

                    const {
                      target: { value },
                    } = event;

                    const guess = guessOrgPrefix(value);

                    orgPrefixInputRef.current?.set(guess);

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
              ref={orgPrefixInputRef}
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
              ref={hostNameInputRef}
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
