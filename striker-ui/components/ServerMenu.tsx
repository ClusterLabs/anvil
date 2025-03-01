import { MoreVert as MoreVertIcon } from '@mui/icons-material';
import { Box } from '@mui/material';
import { capitalize } from 'lodash';
import { useCallback, useMemo } from 'react';

import api from '../lib/api';
import ButtonWithMenu from './ButtonWithMenu';
import { MAP_TO_COLOUR } from './ContainedButton';
import handleAPIError from '../lib/handleAPIError';
import { BodyText } from './Text';
import useConfirmDialog from '../hooks/useConfirmDialog';
import Divider from './Divider';

const ServerMenu = <Node extends NodeMinimum, Server extends ServerMinimum>(
  ...[props]: Parameters<React.FC<ServerMenuProps<Node, Server>>>
): ReturnType<React.FC<ServerMenuProps<Node, Server>>> => {
  const { node, server, slotProps } = props;

  const {
    confirmDialog,
    setConfirmDialogOpen,
    setConfirmDialogProps,
    finishConfirm,
  } = useConfirmDialog();

  const on = useMemo(() => ['running'].includes(server.state), [server.state]);

  const handlePowerOption = useCallback(
    (
        description: React.ReactNode,
        path: string,
        options?: {
          colour?: Exclude<ContainedButtonBackground, 'normal'>;
        },
      ) =>
      (key: string) => {
        const label = capitalize(key);

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
                      Successfully registered {key} job on {server.name}.
                    </>
                  ),
                });
              })
              .catch((error) => {
                const emsg = handleAPIError(error);

                emsg.children = (
                  <>
                    Failed to register {key} job on {server.name}.{' '}
                    {emsg.children}
                  </>
                );

                finishConfirm('Error', emsg);
              });
          },
          proceedColour: options?.colour,
          titleText: `${label} server ${server.name}?`,
        });

        setConfirmDialogOpen(true);
      },
    [finishConfirm, server.name, setConfirmDialogOpen, setConfirmDialogProps],
  );

  const options = useMemo<Record<string, ServerOption>>(() => {
    const ops: Record<string, ServerOption> = {
      server: {
        href: () => `/server?name=${server.name}`,
        render: () => (
          <BodyText inheritColour noWrap>
            Manage server
          </BodyText>
        ),
      },
      node: {
        href: () => `/anvil?name=${node.name}`,
        render: () => (
          <BodyText inheritColour noWrap>
            On node: {node.name}
          </BodyText>
        ),
      },
      'subheader-power': {
        render: () => (
          <Divider orientation="horizontal" sx={{ margin: '.4em 0' }} />
        ),
      },
    };

    const forceOff: ServerOption = {
      disabled: () => !on,
      onClick: handlePowerOption(
        <>
          This is equal to pulling the power cord, which may cause data loss or
          system corruption.
        </>,
        `/command/stop-server/${server.uuid}?force=1`,
        {
          colour: 'red',
        },
      ),
      render: () => (
        <BodyText color={MAP_TO_COLOUR.red} inheritColour noWrap>
          Force off
        </BodyText>
      ),
    };

    const powerOff: ServerOption = {
      disabled: () => !on,
      onClick: handlePowerOption(
        <>
          This is equal to pushing the power button. If the server doesn&apos;t
          respond to the corresponding signals, you may have to manually shut it
          down.
        </>,
        `/command/stop-server/${server.uuid}`,
      ),
      render: () => (
        <BodyText inheritColour noWrap>
          Power off
        </BodyText>
      ),
    };

    const powerOn: ServerOption = {
      disabled: () => on,
      onClick: handlePowerOption(
        <>This is equal to pushing the power button.</>,
        `/command/start-server/${server.uuid}`,
      ),
      render: () => (
        <BodyText inheritColour noWrap>
          Power on
        </BodyText>
      ),
    };

    ops['power on'] = powerOn;

    ops['power off'] = powerOff;
    ops['force off'] = forceOff;

    return ops;
  }, [handlePowerOption, node.name, on, server.name, server.uuid]);

  return (
    <Box>
      <ButtonWithMenu<ServerOption>
        getItemDisabled={(key, value) => value.disabled?.call(null, key, value)}
        getItemHref={(key, value) => value.href?.call(null, key, value)}
        items={options}
        onItemClick={(key, value) => value.onClick?.call(null, key, value)}
        renderItem={(key, value) => value.render(key, value)}
        {...slotProps?.button}
      >
        <MoreVertIcon
          fontSize={slotProps?.button?.slotProps?.button?.icon?.size}
        />
      </ButtonWithMenu>
      {confirmDialog}
    </Box>
  );
};

export default ServerMenu;
