import { Grid } from '@mui/material';
import { FC, ReactNode, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import mailServerListSchema from './schema';
import SelectWithLabel from '../SelectWithLabel';
import useFormikUtils from '../../hooks/useFormikUtils';
import UncontrolledInput from '../UncontrolledInput';

const AddMailServerForm: FC<AddMailServerFormProps> = (props) => {
  const {
    localhostDomain = '',
    mailServerUuid,
    previousFormikValues,
    tools,
  } = props;

  const msUuid = useMemo<string>(
    () => mailServerUuid ?? uuidv4(),
    [mailServerUuid],
  );

  const {
    disableAutocomplete,
    disabledSubmit,
    formik,
    formikErrors,
    handleChange,
  } = useFormikUtils<MailServerFormikValues>({
    initialValues: previousFormikValues ?? {
      [msUuid]: {
        address: '',
        authentication: 'none',
        heloDomain: localhostDomain,
        port: 587,
        security: 'none',
        uuid: msUuid,
      },
    },
    onSubmit: (values, { setSubmitting }) => {
      const { [msUuid]: mailServer } = values;

      let actionProceedText: string = 'Add';
      let errorMessage: ReactNode = <>Failed to add mail server.</>;
      let method: 'post' | 'put' = 'post';
      let successMessage = <>Mail server added.</>;
      let titleText: string = 'Add mail server with the following?';
      let url = '/mail-server';

      if (previousFormikValues) {
        actionProceedText = 'Update';
        errorMessage = <>Failed to update mail server.</>;
        method = 'put';
        successMessage = <>Mail server updated.</>;
        titleText = `Update ${mailServer.address}:${mailServer.port} with the following?`;
        url += `/${msUuid}`;
      }

      const { confirmPassword, uuid, ...rest } = mailServer;

      tools.confirm.prepare({
        actionProceedText,
        content: <FormSummary entries={rest} />,
        onCancelAppend: () => setSubmitting(false),
        onProceedAppend: () => {
          tools.confirm.loading(true);

          api[method](url, mailServer)
            .then(() => {
              tools.confirm.finish('Success', { children: successMessage });

              tools[method === 'post' ? 'add' : 'edit'].open(false);
            })
            .catch((error) => {
              const emsg = handleAPIError(error);

              emsg.children = (
                <>
                  {errorMessage} {emsg.children}
                </>
              );

              tools.confirm.finish('Error', emsg);

              setSubmitting(false);
            });
        },
        titleText,
      });

      tools.confirm.open(true);
    },
    validationSchema: mailServerListSchema,
  });

  const addressChain = useMemo<string>(() => `${msUuid}.address`, [msUuid]);
  const authenticationChain = useMemo<string>(
    () => `${msUuid}.authentication`,
    [msUuid],
  );
  const confirmPasswordChain = useMemo<string>(
    () => `${msUuid}.confirmPassword`,
    [msUuid],
  );
  const heloDomainChain = useMemo<string>(
    () => `${msUuid}.heloDomain`,
    [msUuid],
  );
  const passwordChain = useMemo<string>(() => `${msUuid}.password`, [msUuid]);
  const portChain = useMemo<string>(() => `${msUuid}.port`, [msUuid]);
  const securityChain = useMemo<string>(() => `${msUuid}.security`, [msUuid]);
  const usernameChain = useMemo<string>(() => `${msUuid}.username`, [msUuid]);

  return (
    <Grid
      component="form"
      onSubmit={(event) => {
        event.preventDefault();

        formik.submitForm();
      }}
      container
      columns={{ xs: 1, sm: 2 }}
      spacing="1em"
    >
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={addressChain}
              label="Server address"
              name={addressChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              required
              value={formik.values[msUuid].address}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={portChain}
              label="Server port"
              name={portChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              required
              type="number"
              value={formik.values[msUuid].port}
            />
          }
        />
      </Grid>
      <Grid item sm={2} xs={1}>
        <UncontrolledInput
          input={
            <SelectWithLabel
              id={securityChain}
              label="Server security type"
              name={securityChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              required
              selectItems={['none', 'starttls', 'tls-ssl']}
              value={formik.values[msUuid].security}
            />
          }
        />
      </Grid>
      <Grid item sm={2} xs={1}>
        <UncontrolledInput
          input={
            <SelectWithLabel
              id={authenticationChain}
              label="Server authentication method"
              name={authenticationChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              required
              selectItems={['none', 'plain-text', 'encrypted']}
              value={formik.values[msUuid].authentication}
            />
          }
        />
      </Grid>
      <Grid item sm={2} xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={heloDomainChain}
              label="HELO domain"
              name={heloDomainChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              required
              value={formik.values[msUuid].heloDomain}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={usernameChain}
              inputProps={disableAutocomplete()}
              label="Server username"
              name={usernameChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              value={formik.values[msUuid].username}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={passwordChain}
              inputProps={disableAutocomplete()}
              label="Server password"
              name={passwordChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              type="password"
              value={formik.values[msUuid].password}
            />
          }
        />
      </Grid>
      <Grid item xs={1} />
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={confirmPasswordChain}
              inputProps={disableAutocomplete()}
              label="Confirm password"
              name={confirmPasswordChain}
              onBlur={formik.handleBlur}
              onChange={handleChange}
              type="password"
              value={formik.values[msUuid].confirmPassword}
            />
          }
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
              children: previousFormikValues ? 'Update' : 'Add',
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default AddMailServerForm;
