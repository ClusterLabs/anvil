import { forwardRef, useCallback, useMemo, useRef, useState } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import api from '../../lib/api';
import buildMapToMessageSetter from '../../lib/buildMapToMessageSetter';
import buildObjectStateSetterCallback from '../../lib/buildObjectStateSetterCallback';
import CheckboxWithLabel from '../CheckboxWithLabel';
import ConfirmDialog from '../ConfirmDialog';
import FlexBox from '../FlexBox';
import Grid from '../Grid';
import handleAPIError from '../../lib/handleAPIError';
import IconButton from '../IconButton';
import InputWithRef, { InputForwardedRefContent } from '../InputWithRef';
import { Message } from '../MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  buildIPAddressTestBatch,
  buildPeacefulStringTestBatch,
} from '../../lib/test_input';
import { HeaderText } from '../Text';

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
  const inputPeerDBPortRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerIPAddressRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerPasswordRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerSSHPortRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputPeerUserRef = useRef<InputForwardedRefContent<'string'>>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [formValidity, setFormValidity] = useState<{
    [inputTestID: string]: boolean;
  }>({});
  const [isEnablePingTest, setIsEnablePingTest] = useState<boolean>(true);
  const [isSubmittingAddPeer, setIsSubmittingAddPeer] =
    useState<boolean>(false);

  const buildInputFirstRenderFunction = useCallback(
    (key: string) =>
      ({ isValid }: InputFirstRenderFunctionArgs) => {
        setFormValidity(buildObjectStateSetterCallback(key, isValid));
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
            'add-peer-ip-address': {
              children: (
                <FlexBox row spacing=".3em">
                  <InputWithRef
                    input={
                      <OutlinedInputWithLabel
                        id="add-peer-ip-address-input"
                        inputProps={{
                          // Initiallize the field as read-only, then unlock
                          // when the user focuses; this avoids browser's
                          // auto-complete.
                          readOnly: true,
                          onFocus: (event) => {
                            event.target.readOnly = false;
                          },
                        }}
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
      titleText={
        <>
          <HeaderText>Add a peer</HeaderText>
          <IconButton
            mapPreset="close"
            onClick={() => {
              if (ref && 'current' in ref) {
                (
                  ref as React.RefObject<ConfirmDialogForwardedRefContent>
                ).current.setOpen?.call(null, false);
              }
            }}
            variant="redcontained"
          />
        </>
      }
    />
  );
});

AddPeerDialog.displayName = 'AddPeerDialog';

export default AddPeerDialog;
