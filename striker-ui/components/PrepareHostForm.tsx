import {
  Visibility as MUIVisibilityIcon,
  VisibilityOff as MUIVisibilityOffIcon,
} from '@mui/icons-material';
import { IconButton as MUIIconButton } from '@mui/material';
import { FC, useCallback, useMemo, useRef, useState } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';
import INPUT_TYPES from '../lib/consts/INPUT_TYPES';

import handleAPIError from '../lib/handleAPIError';
import mainAxiosInstance from '../lib/singletons/mainAxiosInstance';
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
import MessageGroup, { MessageGroupForwardedRefContent } from './MessageGroup';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import RadioGroupWithLabel from './RadioGroupWithLabel';
import { BodyText, HeaderText, MonoText } from './Text';

const ENTERPRISE_KEY_LABEL = 'Alteeve enterprise key';
const HOST_IP_LABEL = 'Host IP address';
const HOST_NAME_LABEL = 'Host name';
const REDHAT_PASSWORD_LABEL = 'RedHat password';
const REDHAT_USER_LABEL = 'RedHat user';

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
  const gateFormRef = useRef<GateFormForwardedRefContent>({});
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
  const [isShowAccessSubmit, setIsShowAccessSubmit] = useState<boolean>(true);
  const [isShowOptionalSection, setIsShowOptionalSection] =
    useState<boolean>(false);
  const [isShowRedhatPassword, setIsShowRedhatPassword] =
    useState<boolean>(false);
  const [isShowRedhatSection, setIsShowRedhatSection] =
    useState<boolean>(false);

  const setHostNameInputMessage = useCallback((message?) => {
    messageGroupRef.current.setMessage?.call(null, IT_IDS.hostName, message);
  }, []);
  const setEnterpriseKeyInputMessage = useCallback((message?) => {
    messageGroupRef.current.setMessage?.call(
      null,
      IT_IDS.enterpriseKey,
      message,
    );
  }, []);
  const setRedhatPasswordInputMessage = useCallback((message?) => {
    messageGroupRef.current.setMessage?.call(
      null,
      IT_IDS.redhatPassword,
      message,
    );
  }, []);
  const setRedhatUserInputMessage = useCallback((message?) => {
    messageGroupRef.current.setMessage?.call(null, IT_IDS.redhatUser, message);
  }, []);

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
        allowSubmit={isShowAccessSubmit}
        gridProps={{
          wrapperBoxProps: {
            sx: {
              display: isShowAccessSection ? 'flex' : 'none',
            },
          },
        }}
        identifierInputTestBatchBuilder={(setMessage) =>
          buildIPAddressTestBatch(
            HOST_IP_LABEL,
            () => {
              setMessage();
            },
            undefined,
            (message) => {
              setMessage({ children: message, type: 'warning' });
            },
          )
        }
        identifierLabel={HOST_IP_LABEL}
        onIdentifierBlurAppend={({ target: { value } }) => {
          if (connectedHostIPAddress) {
            const isIdentifierChanged = value !== connectedHostIPAddress;

            setIsShowAccessSubmit(isIdentifierChanged);
            setIsShowOptionalSection(!isIdentifierChanged);
          }
        }}
        onSubmitAppend={(
          { getValue: getIdentifier },
          { getValue: getPassphrase },
          setMessage,
          setIsSubmitting,
        ) => {
          mainAxiosInstance
            .put<{
              hostName: string;
              hostOS: string;
              hostUUID: string;
              isConnected: boolean;
              isInetConnected: boolean;
              isOSRegistered: boolean;
            }>(
              '/command/inquire-host',
              {
                ipAddress: getIdentifier?.call(null),
                password: getPassphrase?.call(null),
              },
              {
                transformRequest: (data, headers = {}) => {
                  headers['Content-Type'] = 'application/json';

                  return JSON.stringify(data);
                },
                transformResponse: (data) => JSON.parse(data),
              },
            )
            .then(
              ({
                data: {
                  hostName,
                  hostOS,
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

                  setConnectedHostIPAddress(getIdentifier?.call(null));
                  setIsShowAccessSubmit(false);
                  setIsShowOptionalSection(true);
                } else {
                  setMessage?.call(null, {
                    children: `Failed to establish a connection with the given host credentials.`,
                    type: 'error',
                  });
                }
              },
            )
            .catch((error) => {
              const errorMessage = handleAPIError(error);

              setMessage?.call(null, errorMessage);
            })
            .finally(() => {
              setIsSubmitting(false);
            });
        }}
        passphraseLabel="Host root password"
        ref={gateFormRef}
        submitLabel="Test access"
      />
    ),
    [
      isShowAccessSection,
      isShowAccessSubmit,
      connectedHostIPAddress,
      testInput,
    ],
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

  const submitSection = useMemo(
    () => (
      <FlexBox
        row
        sx={{
          display: isShowOptionalSection ? 'flex' : 'none',
          justifyContent: 'flex-end',
        }}
      >
        <ContainedButton
          disabled={
            isInputHostNameValid &&
            isInputEnterpriseKeyValid &&
            isInputRedhatUserValid &&
            isInputRedhatPasswordValid
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
              node: { label: 'Node', value: 'node' },
              dr: { label: 'Disaster Recovery (DR) host', value: 'dr' },
            }}
          />
          {accessSection}
          {optionalSection}
          {redhatSection}
          <MessageGroup count={1} ref={messageGroupRef} />
          {submitSection}
        </FlexBox>
      </Panel>
      <ConfirmDialog
        actionProceedText="Prepare"
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
                    {inputHostType === 'dr' ? 'Disaster Recovery (DR)' : 'Node'}
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
          //
        }}
        ref={confirmDialogRef}
        titleText="Confirm host preparation"
      />
    </>
  );
};

export default PrepareHostForm;
