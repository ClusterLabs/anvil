import {
  Visibility as MUIVisibilityIcon,
  VisibilityOff as MUIVisibilityOffIcon,
} from '@mui/icons-material';
import { Box as MUIBox, IconButton as MUIIconButton } from '@mui/material';
import { FC, useCallback, useMemo, useRef, useState } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';
import INPUT_TYPES from '../lib/consts/INPUT_TYPES';

import api from '../lib/api';
import handleAPIError from '../lib/handleAPIError';
import {
  buildDomainTestBatch,
  buildIPAddressTestBatch,
  buildPeacefulStringTestBatch,
  buildUUIDTestBatch,
  createTestInputFunction,
} from '../lib/test_input';

import ConfirmDialog from './ConfirmDialog';
import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GateForm from './GateForm';
import Grid from './Grid';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import { Message } from './MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from './MessageGroup';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import RadioGroupWithLabel from './RadioGroupWithLabel';
import Spinner from './Spinner';
import { BodyText, HeaderText, MonoText } from './Text';

const ENTERPRISE_KEY_LABEL = 'Alteeve enterprise key';
const HOST_IP_LABEL = 'Host IP address';
const HOST_NAME_LABEL = 'Host name';
const REDHAT_PASSWORD_LABEL = 'RedHat password';
const REDHAT_USER_LABEL = 'RedHat user';
const SUCCESS_MESSAGE_TIMEOUT = 5000;

const IT_IDS = {
  enterpriseKey: 'enterpriseKey',
  hostName: 'hostName',
  redhatPassword: 'redhatPassword',
  redhatUser: 'redhatUser',
};

const GRID_COLUMNS: Exclude<GridProps['columns'], undefined> = {
  xs: 1,
  sm: 2,
};
const GRID_SPACING: Exclude<GridProps['spacing'], undefined> = '1em';

const PrepareHostForm: FC = () => {
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const inputEnterpriseKeyRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputHostNameRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputRedhatPassword = useRef<InputForwardedRefContent<'string'>>({});
  const inputRedhatUser = useRef<InputForwardedRefContent<'string'>>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmValues, setConfirmValues] = useState<
    | {
        enterpriseKey: string;
        hostName: string;
        redhatPassword: string;
        redhatPasswordHidden: string;
        redhatUser: string;
      }
    | undefined
  >();
  const [connectedHostIPAddress, setConnectedHostIPAddress] = useState<
    string | undefined
  >();
  const [connectedHostPassword, setConnectedHostPassword] = useState<
    string | undefined
  >();
  const [connectedHostUUID, setConnectedHostUUID] = useState<string>('');
  const [inputHostType, setInputHostType] = useState<string>('');
  const [isInputEnterpriseKeyValid, setIsInputEnterpriseKeyValid] =
    useState<boolean>(true);
  const [isInputHostNameValid, setIsInputHostNameValid] =
    useState<boolean>(false);
  const [isInputRedhatPasswordValid, setIsInputRedhatPasswordValid] =
    useState<boolean>(true);
  const [isInputRedhatUserValid, setIsInputRedhatUserValid] =
    useState<boolean>(true);
  const [isShowAccessSection, setIsShowAccessSection] =
    useState<boolean>(false);
  const [isShowOptionalSection, setIsShowOptionalSection] =
    useState<boolean>(false);
  const [isShowRedhatPassword, setIsShowRedhatPassword] =
    useState<boolean>(false);
  const [isShowRedhatSection, setIsShowRedhatSection] =
    useState<boolean>(false);
  const [isSubmittingPrepareHost, setIsSubmittingPrepareHost] =
    useState<boolean>(false);

  const setHostNameInputMessage = useCallback((message?: Message) => {
    messageGroupRef.current.setMessage?.call(null, IT_IDS.hostName, message);
  }, []);
  const setEnterpriseKeyInputMessage = useCallback((message?: Message) => {
    messageGroupRef.current.setMessage?.call(
      null,
      IT_IDS.enterpriseKey,
      message,
    );
  }, []);
  const setRedhatPasswordInputMessage = useCallback((message?: Message) => {
    messageGroupRef.current.setMessage?.call(
      null,
      IT_IDS.redhatPassword,
      message,
    );
  }, []);
  const setRedhatUserInputMessage = useCallback((message?: Message) => {
    messageGroupRef.current.setMessage?.call(null, IT_IDS.redhatUser, message);
  }, []);
  const setSubmitPrepareHostMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(
        null,
        'submitPrepareHost',
        message,
      ),
    [],
  );

  const inputTests = useMemo(
    () => ({
      [IT_IDS.enterpriseKey]: buildUUIDTestBatch(
        ENTERPRISE_KEY_LABEL,
        () => {
          setEnterpriseKeyInputMessage();
        },
        undefined,
        (message) => {
          setEnterpriseKeyInputMessage({ children: message, type: 'warning' });
        },
      ),
      [IT_IDS.hostName]: buildDomainTestBatch(
        HOST_NAME_LABEL,
        () => {
          setHostNameInputMessage();
        },
        undefined,
        (message) => {
          setHostNameInputMessage({ children: message, type: 'warning' });
        },
      ),
      [IT_IDS.redhatPassword]: buildPeacefulStringTestBatch(
        REDHAT_PASSWORD_LABEL,
        () => {
          setRedhatPasswordInputMessage();
        },
        undefined,
        (message) => {
          setRedhatPasswordInputMessage({ children: message, type: 'warning' });
        },
      ),
      [IT_IDS.redhatUser]: buildPeacefulStringTestBatch(
        REDHAT_USER_LABEL,
        () => {
          setRedhatUserInputMessage();
        },
        undefined,
        (message) => {
          setRedhatUserInputMessage({ children: message, type: 'warning' });
        },
      ),
    }),
    [
      setEnterpriseKeyInputMessage,
      setHostNameInputMessage,
      setRedhatPasswordInputMessage,
      setRedhatUserInputMessage,
    ],
  );
  const testInput = useMemo(
    () => createTestInputFunction(inputTests),
    [inputTests],
  );

  const redhatElementSxDisplay = useMemo(
    () => (isShowRedhatSection ? undefined : 'none'),
    [isShowRedhatSection],
  );

  const accessSection = useMemo(
    () => (
      <GateForm
        gridProps={{
          wrapperBoxProps: {
            sx: {
              display: isShowAccessSection ? 'flex' : 'none',
            },
          },
        }}
        identifierInputTestBatchBuilder={buildIPAddressTestBatch}
        identifierLabel={HOST_IP_LABEL}
        onIdentifierBlurAppend={({ target: { value } }) => {
          if (connectedHostIPAddress) {
            const isIdentifierChanged = value !== connectedHostIPAddress;

            setIsShowOptionalSection(!isIdentifierChanged);
            setIsShowRedhatSection(!isIdentifierChanged);
          }
        }}
        onSubmitAppend={(
          ipAddress,
          password,
          setGateMessage,
          setGateIsSubmitting,
        ) => {
          const body = { ipAddress, password };

          api
            .put<APICommandInquireHostResponseBody>(
              '/command/inquire-host',
              body,
            )
            .then(
              ({
                data: {
                  hostName,
                  hostOS,
                  hostUUID,
                  isConnected,
                  isInetConnected,
                  isOSRegistered,
                },
              }) => {
                if (isConnected) {
                  inputHostNameRef.current.setValue?.call(null, hostName);

                  const valid = testInput({
                    inputs: { [IT_IDS.hostName]: { value: hostName } },
                  });
                  setIsInputHostNameValid(valid);

                  if (
                    isInetConnected &&
                    /rhel/i.test(hostOS) &&
                    !isOSRegistered
                  ) {
                    setIsShowRedhatSection(true);
                  }

                  setConnectedHostIPAddress(ipAddress);
                  setConnectedHostPassword(password);
                  setConnectedHostUUID(hostUUID);

                  setIsShowOptionalSection(true);
                } else {
                  setGateMessage({
                    children: `Failed to establish a connection with the given host credentials.`,
                    type: 'error',
                  });
                }
              },
            )
            .catch((apiError) => {
              const emsg = handleAPIError(apiError);

              setGateMessage?.call(null, emsg);
            })
            .finally(() => {
              setGateIsSubmitting(false);
            });
        }}
        passphraseLabel="Host root password"
        submitLabel={`${connectedHostUUID ? 'Retest' : 'Test'} access`}
      />
    ),
    [connectedHostIPAddress, connectedHostUUID, isShowAccessSection, testInput],
  );

  const optionalSection = useMemo(
    () => (
      <Grid
        columns={GRID_COLUMNS}
        layout={{
          'preparehost-host-name': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{ sx: { width: '100%' } }}
                    id="preparehost-host-name-input"
                    inputProps={{
                      onBlur: ({ target: { value } }) => {
                        const valid = testInput({
                          inputs: { [IT_IDS.hostName]: { value } },
                        });
                        setIsInputHostNameValid(valid);
                      },
                      onFocus: () => {
                        setHostNameInputMessage();
                      },
                    }}
                    label={HOST_NAME_LABEL}
                  />
                }
                ref={inputHostNameRef}
              />
            ),
          },
          'preparehost-enterprise-key': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{ sx: { width: '100%' } }}
                    id="preparehost-enterprise-key-input"
                    inputProps={{
                      onBlur: ({ target: { value } }) => {
                        if (value) {
                          const valid = testInput({
                            inputs: { [IT_IDS.enterpriseKey]: { value } },
                          });
                          setIsInputEnterpriseKeyValid(valid);
                        }
                      },
                      onFocus: () => {
                        setEnterpriseKeyInputMessage();
                      },
                    }}
                    label={ENTERPRISE_KEY_LABEL}
                  />
                }
                ref={inputEnterpriseKeyRef}
              />
            ),
          },
        }}
        spacing={GRID_SPACING}
        wrapperBoxProps={{
          sx: { display: isShowOptionalSection ? undefined : 'none' },
        }}
      />
    ),
    [
      isShowOptionalSection,
      setEnterpriseKeyInputMessage,
      setHostNameInputMessage,
      testInput,
    ],
  );

  const redhatSection = useMemo(
    () => (
      <Grid
        columns={GRID_COLUMNS}
        layout={{
          'preparehost-redhat-user': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{ sx: { width: '100%' } }}
                    id="preparehost-redhat-user-input"
                    inputProps={{
                      onBlur: ({ target: { value } }) => {
                        if (value) {
                          const valid = testInput({
                            inputs: { [IT_IDS.redhatUser]: { value } },
                          });
                          setIsInputRedhatUserValid(valid);
                        }
                      },
                      onFocus: () => {
                        setRedhatUserInputMessage();
                      },
                    }}
                    label={REDHAT_USER_LABEL}
                  />
                }
                ref={inputRedhatUser}
              />
            ),
          },
          'preparehost-redhat-password': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{ sx: { width: '100%' } }}
                    id="preparehost-redhat-password-input"
                    inputProps={{
                      onBlur: ({ target: { value } }) => {
                        if (value) {
                          const valid = testInput({
                            inputs: { [IT_IDS.redhatPassword]: { value } },
                          });
                          setIsInputRedhatPasswordValid(valid);
                        }
                      },
                      onFocus: () => {
                        setRedhatPasswordInputMessage();
                      },
                      onPasswordVisibilityAppend: (type) => {
                        setIsShowRedhatPassword(type !== INPUT_TYPES.password);
                      },
                      type: INPUT_TYPES.password,
                    }}
                    label={REDHAT_PASSWORD_LABEL}
                  />
                }
                ref={inputRedhatPassword}
              />
            ),
          },
        }}
        spacing={GRID_SPACING}
        wrapperBoxProps={{
          sx: { display: redhatElementSxDisplay },
        }}
      />
    ),
    [
      redhatElementSxDisplay,
      setRedhatPasswordInputMessage,
      setRedhatUserInputMessage,
      testInput,
    ],
  );

  const messageSection = useMemo(
    () => (
      <MUIBox sx={{ display: isShowOptionalSection ? undefined : 'none' }}>
        <MessageGroup count={1} ref={messageGroupRef} />
      </MUIBox>
    ),
    [isShowOptionalSection],
  );

  const submitSection = useMemo(
    () =>
      isSubmittingPrepareHost ? (
        <Spinner mt={0} />
      ) : (
        <FlexBox
          row
          sx={{
            display: isShowOptionalSection ? 'flex' : 'none',
            justifyContent: 'flex-end',
          }}
        >
          <ContainedButton
            disabled={
              !isInputHostNameValid ||
              !isInputEnterpriseKeyValid ||
              !isInputRedhatUserValid ||
              !isInputRedhatPasswordValid
            }
            onClick={() => {
              const redhatPasswordInputValue =
                inputRedhatPassword.current.getValue?.call(null);

              setConfirmValues({
                enterpriseKey:
                  inputEnterpriseKeyRef.current.getValue?.call(null) ||
                  'none; using community version',
                hostName: inputHostNameRef.current.getValue?.call(null) || '',
                redhatPassword: redhatPasswordInputValue || 'none',
                redhatPasswordHidden:
                  redhatPasswordInputValue?.replace(/./g, '*') || 'none',
                redhatUser:
                  inputRedhatUser.current.getValue?.call(null) || 'none',
              });
              setSubmitPrepareHostMessage();

              confirmDialogRef.current.setOpen?.call(null, true);
            }}
          >
            Prepare host
          </ContainedButton>
        </FlexBox>
      ),
    [
      isInputEnterpriseKeyValid,
      isInputHostNameValid,
      isInputRedhatPasswordValid,
      isInputRedhatUserValid,
      isShowOptionalSection,
      isSubmittingPrepareHost,
      setSubmitPrepareHostMessage,
    ],
  );

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Prepare a host to include in Anvil!</HeaderText>
        </PanelHeader>
        <FlexBox>
          <RadioGroupWithLabel
            id="preparehost-host-type"
            label="Host type"
            onChange={(event, value) => {
              setInputHostType(value);
              setIsShowAccessSection(true);
            }}
            radioItems={{
              node: { label: 'Subnode', value: 'node' },
              dr: { label: 'Disaster Recovery (DR) host', value: 'dr' },
            }}
          />
          {accessSection}
          {optionalSection}
          {redhatSection}
          {messageSection}
          {submitSection}
        </FlexBox>
      </Panel>
      <ConfirmDialog
        actionProceedText="Prepare"
        closeOnProceed
        content={
          <Grid
            calculateItemBreakpoints={(index) => ({
              xs: index % 2 === 0 ? 1 : 2,
            })}
            columns={3}
            layout={{
              'preparehost-confirm-host-type-label': {
                children: <BodyText>Host type</BodyText>,
              },
              'preparehost-confirm-host-type-value': {
                children: (
                  <MonoText>
                    {inputHostType === 'dr'
                      ? 'Disaster Recovery (DR)'
                      : 'Subnode'}
                  </MonoText>
                ),
              },
              'preparehost-confirm-host-name-label': {
                children: <BodyText>Host name</BodyText>,
              },
              'preparehost-confirm-host-name-value': {
                children: <MonoText>{confirmValues?.hostName}</MonoText>,
              },
              'preparehost-confirm-enterprise-key-label': {
                children: <BodyText>Alteeve enterprise key</BodyText>,
              },
              'preparehost-confirm-enterprise-key-value': {
                children: <MonoText>{confirmValues?.enterpriseKey}</MonoText>,
              },
              'preparehost-confirm-redhat-user-label': {
                children: <BodyText>RedHat user</BodyText>,
                sx: { display: redhatElementSxDisplay },
              },
              'preparehost-confirm-redhat-user-value': {
                children: <MonoText>{confirmValues?.redhatUser}</MonoText>,
                sx: { display: redhatElementSxDisplay },
              },
              'preparehost-confirm-redhat-password-label': {
                children: <BodyText>RedHat password</BodyText>,
                sx: { display: redhatElementSxDisplay },
              },
              'preparehost-confirm-redhat-password-value': {
                children: (
                  <FlexBox
                    row
                    sx={{
                      height: '100%',
                      maxWidth: '100%',
                    }}
                  >
                    <MonoText
                      sx={{
                        flexGrow: 1,
                        maxWidth: 'calc(100% - 3em)',
                        overflowX: 'scroll',
                      }}
                    >
                      {isShowRedhatPassword
                        ? confirmValues?.redhatPassword
                        : confirmValues?.redhatPasswordHidden}
                    </MonoText>
                    <MUIIconButton
                      onClick={() => {
                        setIsShowRedhatPassword((previous) => !previous);
                      }}
                      sx={{ color: GREY, padding: 0 }}
                    >
                      {isShowRedhatPassword ? (
                        <MUIVisibilityOffIcon />
                      ) : (
                        <MUIVisibilityIcon />
                      )}
                    </MUIIconButton>
                  </FlexBox>
                ),
                sx: { display: redhatElementSxDisplay },
              },
            }}
            spacing=".6em"
          />
        }
        onCancelAppend={() => {
          setIsShowRedhatPassword(false);
        }}
        onProceedAppend={() => {
          setIsSubmittingPrepareHost(true);

          api
            .put('/host/prepare', {
              enterpriseUUID:
                inputEnterpriseKeyRef.current.getValue?.call(null),
              hostIPAddress: connectedHostIPAddress,
              hostName: inputHostNameRef.current.getValue?.call(null),
              hostPassword: connectedHostPassword,
              hostType: inputHostType,
              hostUUID: connectedHostUUID,
              redhatPassword: inputRedhatPassword.current.getValue?.call(null),
              redhatUser: inputRedhatUser.current.getValue?.call(null),
            })
            .then(() => {
              setSubmitPrepareHostMessage({
                children: `Successfully initiated prepare host.`,
              });

              setTimeout(() => {
                setSubmitPrepareHostMessage();
              }, SUCCESS_MESSAGE_TIMEOUT);
            })
            .catch((error) => {
              const errorMessage = handleAPIError(error, {
                onResponseErrorAppend: ({ status }) => {
                  let result: Message | undefined;

                  if (status === 400) {
                    result = {
                      children: `The API found invalid values. Did you forget to fill in one of the RedHat fields?`,
                      type: 'warning',
                    };
                  }

                  return result;
                },
              });

              setSubmitPrepareHostMessage(errorMessage);
            })
            .finally(() => {
              setIsSubmittingPrepareHost(false);
            });
        }}
        ref={confirmDialogRef}
        titleText="Confirm host preparation"
      />
    </>
  );
};

export default PrepareHostForm;
