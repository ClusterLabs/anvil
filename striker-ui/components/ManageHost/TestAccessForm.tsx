import { FC, useCallback, useMemo, useRef, useState } from 'react';
import { Grid } from '@mui/material';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';
import Spinner from '../Spinner';
import schema from './testAccessSchema';

const TestAccessForm: FC<TestAccessFormProps> = (props) => {
  const { setResponse } = props;

  const messageGroupRef = useRef<MessageGroupForwardedRefContent>(null);

  const [loadingInquiry, setLoadingInquiry] = useState<boolean>(false);

  const setApiMessage = useCallback(
    (message?: Message) =>
      messageGroupRef?.current?.setMessage?.call(null, 'api', message),
    [],
  );

  const { disabledSubmit, formik, formikErrors, handleChange } =
    useFormikUtils<TestAccessFormikValues>({
      initialValues: {
        ip: '',
        password: '',
      },
      onSubmit: (values, { setSubmitting }) => {
        setApiMessage();
        setLoadingInquiry(true);
        setResponse(undefined);

        const { ip, password } = values;

        api
          .put<APICommandInquireHostResponseBody>('/command/inquire-host', {
            ipAddress: ip,
            password,
          })
          .then(({ data }) => {
            const { isConnected } = data;

            if (!isConnected) {
              setApiMessage({
                children: (
                  <>
                    Failed to connect. Please make sure the credentials are
                    correct, and the host is reachable from this striker.
                  </>
                ),
                type: 'warning',
              });

              return;
            }

            setResponse({
              ...data,
              hostIpAddress: ip,
              hostPassword: password,
            });

            setApiMessage();
          })
          .catch((error) => {
            const emsg = handleAPIError(error);

            emsg.children = (
              <>
                Failed to access {ip}. {emsg.children}
              </>
            );

            setApiMessage(emsg);
          })
          .finally(() => {
            setSubmitting(false);
            setLoadingInquiry(false);
          });
      },
      validationSchema: schema,
    });

  const ipChain = useMemo<string>(() => 'ip', []);
  const passwordChain = useMemo<string>(() => 'password', []);

  return (
    <Grid
      component="form"
      container
      columns={{ xs: 1, sm: 2 }}
      onSubmit={(event) => {
        event.preventDefault();

        formik.submitForm();
      }}
      spacing="1em"
    >
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={ipChain}
              label="IP address"
              name={ipChain}
              onChange={handleChange}
              required
              value={formik.values.ip}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              disableAutofill
              id={passwordChain}
              label="Password"
              name={passwordChain}
              onChange={handleChange}
              required
              type="password"
              value={formik.values.password}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} ref={messageGroupRef} />
      </Grid>
      <Grid item width="100%">
        {loadingInquiry ? (
          <Spinner mt={0} />
        ) : (
          <ActionGroup
            actions={[
              {
                background: 'blue',
                children: 'Test access',
                disabled: disabledSubmit,
                type: 'submit',
              },
            ]}
          />
        )}
      </Grid>
    </Grid>
  );
};

export default TestAccessForm;
