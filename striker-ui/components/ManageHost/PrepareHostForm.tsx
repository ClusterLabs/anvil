import { Grid } from '@mui/material';
import { useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import RadioGroupWithLabel from '../RadioGroupWithLabel';
import { prepareHostSchema } from './schemas';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const HOST_TYPE_OPTIONS: RadioItemList = {
  subnode: {
    label: 'Subnode',
    value: 'subnode',
  },
  dr: {
    label: 'Disaster Recovery (DR) host',
    value: 'dr',
  },
};

const PrepareHostForm: React.FC<PreapreHostFormProps> = (props) => {
  const { host, setResponse, tools } = props;

  const { disabledSubmit, formik, formikErrors, handleChange } =
    useFormikUtils<PrepareHostFormikValues>({
      initialValues: {
        name: host.hostName,
        password: host.hostPassword,
        target: host.target,
        type: '',
        uuid: host.hostUUID,
      },
      onSubmit: (values, { setSubmitting }) => {
        const {
          enterpriseKey,
          name,
          password,
          redhatPassword,
          redhatUsername,
          target,
          type,
          uuid,
        } = values;

        tools.confirm.prepare({
          actionProceedText: 'Prepare',
          content: <FormSummary entries={values} hasPassword />,
          onCancelAppend: () => setSubmitting(false),
          onProceedAppend: () => {
            tools.confirm.loading(true);

            const requestBody: APIPrepareHostRequestBody = {
              enterprise: {
                uuid: enterpriseKey,
              },
              host: {
                name,
                password,
                ssh: {},
                type: type === 'subnode' ? 'node' : type,
                uuid,
              },
              redhat: {
                password: redhatPassword,
                user: redhatUsername,
              },
              target,
            };

            api
              .put('/host/prepare', requestBody)
              .then(() => {
                tools.confirm.finish('Success', {
                  children: <>Started job to prepare host at {target}.</>,
                });

                tools.add.open(false);

                setTimeout(setResponse, 500);
              })
              .catch((error) => {
                const emsg = handleAPIError(error);

                emsg.children = (
                  <>
                    Failed to prepare host at {target}. {emsg.children}
                  </>
                );

                tools.confirm.finish('Error', emsg);

                setSubmitting(false);
              });
          },
          titleText: `Prepare host at ${values.target} with the following?`,
        });

        tools.confirm.open();
      },
      validationSchema: prepareHostSchema,
    });

  const enterpriseKeyChain = useMemo<string>(() => 'enterpriseKey', []);
  const nameChain = useMemo<string>(() => 'name', []);
  const redhatConfirmPasswordChain = useMemo<string>(
    () => 'redhatConfirmPassword',
    [],
  );
  const redhatPasswordChain = useMemo<string>(() => 'redhatPassword', []);
  const redhatUsernameChain = useMemo<string>(() => 'redhatUsername', []);
  const typeChain = useMemo<string>(() => 'type', []);

  const showRedhatSection = useMemo<boolean>(
    () =>
      host.isInetConnected && /rhel/i.test(host.hostOS) && !host.isOSRegistered,
    [host.hostOS, host.isInetConnected, host.isOSRegistered],
  );

  return (
    <Grid
      columns={{ xs: 1, sm: 2 }}
      component="form"
      container
      onSubmit={(event) => {
        event.preventDefault();

        formik.submitForm();
      }}
      spacing="1em"
    >
      <Grid item width="100%">
        <UncontrolledInput
          input={
            <RadioGroupWithLabel
              id={typeChain}
              label="Host type"
              name={typeChain}
              onChange={handleChange}
              radioItems={HOST_TYPE_OPTIONS}
              value={formik.values.type}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={nameChain}
              label="Host name"
              name={nameChain}
              onChange={handleChange}
              required
              value={formik.values.name}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={enterpriseKeyChain}
              label="Alteeve enterprise key"
              name={enterpriseKeyChain}
              onChange={handleChange}
              value={formik.values.enterpriseKey}
            />
          }
        />
      </Grid>
      {showRedhatSection && (
        <>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={redhatUsernameChain}
                  label="RedHat username"
                  name={redhatUsernameChain}
                  onChange={handleChange}
                  value={formik.values.redhatUsername}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={redhatPasswordChain}
                  label="RedHat password"
                  name={redhatPasswordChain}
                  onChange={handleChange}
                  type="password"
                  value={formik.values.redhatPassword}
                />
              }
            />
          </Grid>
          <Grid display={{ xs: 'none', sm: 'initial' }} item sm={1} />
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={redhatConfirmPasswordChain}
                  label="Confirm RedHat password"
                  name={redhatConfirmPasswordChain}
                  onChange={handleChange}
                  type="password"
                  value={formik.values.redhatConfirmPassword}
                />
              }
            />
          </Grid>
        </>
      )}
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ActionGroup
          actions={[
            {
              background: 'blue',
              children: 'Prepare host',
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default PrepareHostForm;
