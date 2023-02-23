import { forwardRef, useCallback, useMemo, useRef, useState } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import api from '../../lib/api';
import buildMapToMessageSetter from '../../lib/buildMapToMessageSetter';
import buildNumberTestBatch from '../../lib/test_input/buildNumberTestBatch';
import buildObjectStateSetterCallback from '../../lib/buildObjectStateSetterCallback';
import CheckboxWithLabel from '../CheckboxWithLabel';
import ConfirmDialog from '../ConfirmDialog';
import FlexBox from '../FlexBox';
import Grid from '../Grid';
import handleAPIError from '../../lib/handleAPIError';
import InputWithRef, { InputForwardedRefContent } from '../InputWithRef';
import { Message } from '../MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  buildIPAddressTestBatch,
  buildPeacefulStringTestBatch,
} from '../../lib/test_input';
import { BodyText } from '../Text';
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';

const IT_IDS = {
  dbPort: 'dbPort',
  ipAddress: 'ipAddress',
  password: 'password',
  sshPort: 'sshPort',
  user: 'user',
};
const LABEL = {
  dbPort: 'DB port',
  ipAddress: 'IP address',
  password: 'Password',
  ping: 'Ping',
  sshPort: 'SSH port',
  user: 'User',
};

const AddPeerDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  AddPeerDialogProps
>(({ formGridColumns = 2 }, ref) => {
  const { protect } = useProtect();

  const inputPeerDBPortRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerIPAddressRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerPasswordRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerSSHPortRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerUserRef = useRef<InputForwardedRefContent<'string'>>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [formValidity, setFormValidity] = useState<{
    [inputTestID: string]: boolean;
  }>({});
  const [isEnablePingTest, setIsEnablePingTest] = useState<boolean>(false);
  const [isSubmittingAddPeer, setIsSubmittingAddPeer] =
    useProtectedState<boolean>(false, protect);

  const buildInputFirstRenderFunction = useCallback(
    (key: string) =>
      ({ isRequired }: { isRequired: boolean }) => {
        setFormValidity(buildObjectStateSetterCallback(key, !isRequired));
      },
    [],
  );
  const buildFinishInputTestBatchFunction = useCallback(
    (key: string) => (result: boolean) => {
      setFormValidity(buildObjectStateSetterCallback(key, result));
    },
    [],
  );
  const setAPIMessage = useCallback((message?: Message) => {
    messageGroupRef.current.setMessage?.call(null, 'api', message);
  }, []);

  const isFormInvalid = useMemo(
    () => Object.values(formValidity).some((isInputValid) => !isInputValid),
    [formValidity],
  );
  const msgSetters = useMemo(
    () => buildMapToMessageSetter(IT_IDS, messageGroupRef),
    [],
  );

  return (
    <ConfirmDialog
      actionProceedText="Add"
      content={
        <Grid
          columns={{ xs: 1, sm: formGridColumns }}
          layout={{
            'add-peer-user-and-ip-address': {
              children: (
                <FlexBox row spacing=".3em">
                  <InputWithRef
                    input={
                      <OutlinedInputWithLabel
                        formControlProps={{
                          sx: { minWidth: '4.6em', width: '25%' },
                        }}
                        id="add-peer-user-input"
                        inputProps={{ placeholder: 'admin' }}
                        label={LABEL.user}
                      />
                    }
                    inputTestBatch={buildPeacefulStringTestBatch(
                      LABEL.user,
                      () => {
                        msgSetters.user();
                      },
                      {
                        onFinishBatch: buildFinishInputTestBatchFunction(
                          IT_IDS.user,
                        ),
                      },
                      (message) => {
                        msgSetters.user({ children: message });
                      },
                    )}
                    onFirstRender={buildInputFirstRenderFunction(IT_IDS.user)}
                    ref={inputPeerUserRef}
                  />
                  <BodyText>@</BodyText>
                  <InputWithRef
                    input={
                      <OutlinedInputWithLabel
                        id="add-peer-ip-address-input"
                        label={LABEL.ipAddress}
                      />
                    }
                    inputTestBatch={buildIPAddressTestBatch(
                      LABEL.ipAddress,
                      () => {
                        msgSetters.ipAddress();
                      },
                      {
                        onFinishBatch: buildFinishInputTestBatchFunction(
                          IT_IDS.ipAddress,
                        ),
                      },
                      (message) => {
                        msgSetters.ipAddress({ children: message });
                      },
                    )}
                    onFirstRender={buildInputFirstRenderFunction(
                      IT_IDS.ipAddress,
                    )}
                    ref={inputPeerIPAddressRef}
                    required
                  />
                </FlexBox>
              ),
            },
            'add-peer-password': {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      fillRow
                      id="add-peer-password-input"
                      label={LABEL.password}
                      type={INPUT_TYPES.password}
                    />
                  }
                  inputTestBatch={buildPeacefulStringTestBatch(
                    LABEL.password,
                    () => {
                      msgSetters.password();
                    },
                    {
                      onFinishBatch: buildFinishInputTestBatchFunction(
                        IT_IDS.password,
                      ),
                    },
                    (message) => {
                      msgSetters.password({ children: message });
                    },
                  )}
                  onFirstRender={buildInputFirstRenderFunction(IT_IDS.password)}
                  ref={inputPeerPasswordRef}
                  required
                />
              ),
            },
            'add-peer-db-and-ssh-port': {
              children: (
                <FlexBox row>
                  <InputWithRef
                    input={
                      <OutlinedInputWithLabel
                        id="add-peer-db-port-input"
                        inputProps={{ placeholder: '5432' }}
                        label={LABEL.dbPort}
                      />
                    }
                    inputTestBatch={buildNumberTestBatch(
                      LABEL.dbPort,
                      () => {
                        msgSetters.dbPort();
                      },
                      {
                        onFinishBatch: buildFinishInputTestBatchFunction(
                          IT_IDS.dbPort,
                        ),
                      },
                      (message) => {
                        msgSetters.dbPort({ children: message });
                      },
                    )}
                    onFirstRender={buildInputFirstRenderFunction(IT_IDS.dbPort)}
                    ref={inputPeerDBPortRef}
                  />
                  <InputWithRef
                    input={
                      <OutlinedInputWithLabel
                        id="add-peer-ssh-port-input"
                        inputProps={{ placeholder: '22' }}
                        label={LABEL.sshPort}
                      />
                    }
                    inputTestBatch={buildNumberTestBatch(
                      LABEL.sshPort,
                      () => {
                        msgSetters.sshPort();
                      },
                      {
                        onFinishBatch: buildFinishInputTestBatchFunction(
                          IT_IDS.sshPort,
                        ),
                      },
                      (message) => {
                        msgSetters.sshPort({ children: message });
                      },
                    )}
                    onFirstRender={buildInputFirstRenderFunction(
                      IT_IDS.sshPort,
                    )}
                    ref={inputPeerSSHPortRef}
                  />
                </FlexBox>
              ),
            },
            'add-peer-is-ping': {
              children: (
                <CheckboxWithLabel
                  checked={isEnablePingTest}
                  label={LABEL.ping}
                  onChange={(event, isChecked) => {
                    setIsEnablePingTest(isChecked);
                  }}
                />
              ),
              sx: { display: 'flex' },
            },
            'add-peer-message-group': {
              children: (
                <MessageGroup
                  count={1}
                  defaultMessageType="warning"
                  ref={messageGroupRef}
                />
              ),
              sm: formGridColumns,
            },
          }}
          spacing="1em"
        />
      }
      dialogProps={{ PaperProps: { sx: { minWidth: '16em' } } }}
      loadingAction={isSubmittingAddPeer}
      onActionAppend={() => {
        setAPIMessage();
      }}
      onProceedAppend={() => {
        setIsSubmittingAddPeer(true);

        api
          .post('/host/connection', {
            ipAddress: inputPeerIPAddressRef.current.getValue?.call(null),
            isPing: isEnablePingTest,
            password: inputPeerPasswordRef.current.getValue?.call(null),
            port: inputPeerDBPortRef.current.getValue?.call(null),
            sshPort: inputPeerSSHPortRef.current.getValue?.call(null),
            user: inputPeerUserRef.current.getValue?.call(null),
          })
          .then(() => {
            setAPIMessage({
              children: `Successfully initiated the peer addition. You can continue to edit the field(s) to add another peer.`,
              type: 'info',
            });
          })
          .catch((error) => {
            const emsg = handleAPIError(error);

            emsg.children = `Failed to add the given peer. ${emsg.children}`;

            setAPIMessage(emsg);
          })
          .finally(() => {
            setIsSubmittingAddPeer(false);
          });
      }}
      proceedButtonProps={{ disabled: isFormInvalid }}
      ref={ref}
      titleText="Add a peer"
    />
  );
});

AddPeerDialog.displayName = 'AddPeerDialog';

export default AddPeerDialog;
