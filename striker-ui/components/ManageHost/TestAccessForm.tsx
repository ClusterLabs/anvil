import { FC, useCallback, useMemo, useRef, useState } from 'react';
import { Grid } from '@mui/material';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import DeleteSshKeyConflictProgress from './DeleteSshKeyConflictProgress';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';
import { testAccessSchema } from './schemas';
import Spinner from '../Spinner';
import { BodyText } from '../Text';

const TestAccessForm: FC<TestAccessFormProps> = (props) => {
  const { setResponse, tools } = props;

  const messageGroupRef = useRef<MessageGroupForwardedRefContent>(null);

  const [deleteJobs, setDeleteJobs] = useState<
    APIDeleteSSHKeyConflictResponseBody['jobs'] | undefined
  >();
  const [deleteProgress, setDeleteProgress] = useState<number>(0);
  const [loadingInquiry, setLoadingInquiry] = useState<boolean>(false);
  const [moreActions, setMoreActions] = useState<ContainedButtonProps[]>([]);

  const setApiMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current?.setMessage?.call(null, 'api', message),
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
        setMoreActions([]);
        setResponse(undefined);
        setDeleteJobs(undefined);

        const { ip, password } = values;

        api
          .put<APICommandInquireHostResponseBody>('/command/inquire-host', {
            ipAddress: ip,
            password,
          })
          .then(({ data }) => {
            const { badSshKeys, isConnected } = data;

            if (badSshKeys) {
              setApiMessage({
                children: (
                  <>
                    Host identification at {ip} changed. If this is valid,
                    please delete the conflicting SSH host key.
                  </>
                ),
                type: 'warning',
              });

              setMoreActions([
                {
                  background: 'red',
                  children: 'Delete keys',
                  onClick: () => {
                    tools.confirm.prepare({
                      actionProceedText: 'Delete',
                      content: (
                        <BodyText>
                          There&apos;s a different host key on {ip}, which could
                          mean a MITM attack. But if this change is expected,
                          you can delete the known host key(s) to resolve the
                          conflict.
                        </BodyText>
                      ),
                      onProceedAppend: () => {
                        tools.confirm.loading(true);

                        api
                          .delete<APIDeleteSSHKeyConflictResponseBody>(
                            '/ssh-key/conflict',
                            {
                              data: badSshKeys,
                            },
                          )
                          .then((response) => {
                            tools.confirm.finish('Success', {
                              children: (
                                <>Started job to delete host key(s) for {ip}.</>
                              ),
                            });

                            setApiMessage();
                            setMoreActions([]);

                            const { data: body } = response;

                            if (!body) return;

                            setDeleteJobs(body.jobs);
                          })
                          .catch((error) => {
                            const emsg = handleAPIError(error);

                            emsg.children = (
                              <>Failed to delete host key(s). {emsg.children}</>
                            );

                            tools.confirm.finish('Error', emsg);
                          });
                      },
                      proceedColour: 'red',
                      titleText: `Delete all known SSH host key(s) for ${ip}?`,
                    });

                    tools.confirm.open(true);
                  },
                  type: 'button',
                },
              ]);

              return;
            }

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
      validationSchema: testAccessSchema,
    });

  const ipChain = useMemo<string>(() => 'ip', []);
  const passwordChain = useMemo<string>(() => 'password', []);

  const deletingSshKeyConflicts = useMemo<boolean>(
    () => Boolean(deleteJobs) && deleteProgress < 100,
    [deleteJobs, deleteProgress],
  );

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
      {deleteJobs && (
        <Grid item width="100%">
          <DeleteSshKeyConflictProgress
            jobs={deleteJobs}
            progress={{
              total: deleteProgress,
              setTotal: setDeleteProgress,
            }}
          />
        </Grid>
      )}
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} ref={messageGroupRef} />
      </Grid>
      <Grid item width="100%">
        {loadingInquiry ? (
          <Spinner mt={0} />
        ) : (
          <ActionGroup
            actions={[
              ...moreActions,
              {
                background: 'blue',
                children: 'Test access',
                disabled: disabledSubmit || deletingSshKeyConflicts,
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
