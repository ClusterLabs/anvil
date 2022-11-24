import { forwardRef, useRef, useState } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import CheckboxWithLabel from '../CheckboxWithLabel';
import ConfirmDialog from '../ConfirmDialog';
import FlexBox from '../FlexBox';
import Grid from '../Grid';
import InputWithRef, { InputForwardedRefContent } from '../InputWithRef';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { BodyText } from '../Text';

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

  const [isEnablePingTest, setIsEnablePingTest] = useState<boolean>(false);

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
                    ref={inputPeerUserRef}
                  />
                  <BodyText>@</BodyText>
                  <InputWithRef
                    input={
                      <OutlinedInputWithLabel
                        id="add-peer-ip-address-input"
                        label={LABEL.ipAddress}
                        required
                      />
                    }
                    ref={inputPeerIPAddressRef}
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
                      required
                      type={INPUT_TYPES.password}
                    />
                  }
                  ref={inputPeerPasswordRef}
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
              children: <MessageGroup />,
              sm: formGridColumns,
            },
          }}
          spacing="1em"
        />
      }
      dialogProps={{ PaperProps: { sx: { minWidth: '16em' } } }}
      ref={ref}
      titleText="Add a peer"
    />
  );
});

AddPeerDialog.displayName = 'AddPeerDialog';

export default AddPeerDialog;
