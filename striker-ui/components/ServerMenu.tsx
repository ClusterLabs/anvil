import { PowerSettingsNew as PowerSettingsNewIcon } from '@mui/icons-material';
import { Box } from '@mui/material';
import { FC, useMemo } from 'react';

import api from '../lib/api';
import ButtonWithMenu from './ButtonWithMenu';
import { MAP_TO_COLOUR } from './ContainedButton';
import handleAPIError from '../lib/handleAPIError';
import { BodyText } from './Text';
import useConfirmDialog from '../hooks/useConfirmDialog';

const ServerMenu: FC<ServerMenuProps> = (props) => {
  const {
    // Props to ignore, for now:
    getItemDisabled,
    items,
    onItemClick,
    renderItem,
    // ----------
    serverName,
    serverState,
    serverUuid,
    ...buttonWithMenuProps
  } = props;

  const {
    confirmDialog,
    setConfirmDialogOpen,
    setConfirmDialogProps,
    finishConfirm,
  } = useConfirmDialog();

  const powerOptions = useMemo<MapToServerPowerOption>(
    () => ({
      'force-off': {
        colour: 'red',
        description: (
          <>
            This is equal to pulling the power cord, which may cause data loss
            or system corruption.
          </>
        ),
        label: 'Force off',
        path: `/command/stop-server/${serverUuid}?force=1`,
      },
      'power-off': {
        description: (
          <>
            This is equal to pushing the power button. If the server
            doesn&apos;t respond to the corresponding signals, you may have to
            manually shut it down.
          </>
        ),
        label: 'Power off',
        path: `/command/stop-server/${serverUuid}`,
      },
      'power-on': {
        description: <>This is equal to pushing the power button.</>,
        label: 'Power on',
        path: `/command/start-server/${serverUuid}`,
      },
    }),
    [serverUuid],
  );

  return (
    <Box>
      <ButtonWithMenu
        getItemDisabled={(key) => {
          const optionOn = key.includes('on');
          const serverRunning = serverState === 'running';

          return serverRunning === optionOn;
        }}
        items={powerOptions}
        onItemClick={(key, value) => {
          const { colour, description, label, path } = value;

          const op = label.toLocaleLowerCase();

          setConfirmDialogProps({
            actionProceedText: label,
            content: <BodyText>{description}</BodyText>,
            onProceedAppend: () => {
              setConfirmDialogProps((previous) => ({
                ...previous,
                loading: true,
              }));

              api
                .put(path)
                .then(() => {
                  finishConfirm('Success', {
                    children: (
                      <>
                        Successfully registered {op} job on {serverName}.
                      </>
                    ),
                  });
                })
                .catch((error) => {
                  const emsg = handleAPIError(error);

                  emsg.children = (
                    <>
                      Failed to register {op} job on {serverName}; CAUSE:{' '}
                      {emsg.children}.
                    </>
                  );

                  finishConfirm('Error', emsg);
                });
            },
            proceedColour: colour,
            titleText: `${label} server ${serverName}?`,
          });
          setConfirmDialogOpen(true);
        }}
        renderItem={(key, value) => {
          const { colour, label } = value;

          let ccode: string | undefined;

          if (colour) {
            ccode = MAP_TO_COLOUR[colour];
          }

          return (
            <BodyText inheritColour color={ccode}>
              {label}
            </BodyText>
          );
        }}
        {...buttonWithMenuProps}
      >
        <PowerSettingsNewIcon
          fontSize={buttonWithMenuProps?.iconButtonProps?.size}
        />
      </ButtonWithMenu>
      {confirmDialog}
    </Box>
  );
};

export default ServerMenu;
