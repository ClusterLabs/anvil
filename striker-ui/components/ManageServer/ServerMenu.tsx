import MuiMoreVertIcon from '@mui/icons-material/MoreVert';
import MuiBox from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import { useMemo, useRef } from 'react';

import ButtonWithMenu from '../ButtonWithMenu';
import { MAP_TO_COLOUR } from '../ContainedButton';
import Divider from '../Divider';
import handleAction from './handleAction';
import { BodyText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';

const ServerMenu = <Node extends NodeMinimum, Server extends ServerMinimum>(
  ...[props]: Parameters<React.FC<ServerMenuProps<Node, Server>>>
): ReturnType<React.FC<ServerMenuProps<Node, Server>>> => {
  const { node, server, slotProps } = props;

  const {
    confirmDialog,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
    finishConfirm,
  } = useConfirmDialog();

  const confirm = useRef<CrudListFormTools>({
    add: { open: () => null },
    confirm: {
      finish: finishConfirm,
      loading: setConfirmDialogLoading,
      open: (v = true) => setConfirmDialogOpen(v),
      prepare: setConfirmDialogProps,
    },
    edit: { open: () => null },
  });

  const off = useMemo(() => server.state === 'shut off', [server.state]);

  const provisioning = useMemo(
    () => server.state === 'provisioning',
    [server.state],
  );

  const options = useMemo<Record<string, ServerOption>>(() => {
    const ops: Record<string, ServerOption> = {
      server: {
        disabled: () => provisioning,
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
      disabled: () => off,
      onClick: () => {
        handleAction(
          confirm.current,
          `/command/stop-server/${server.uuid}?force=1`,
          `Force off server ${server.name}?`,
          {
            dangerous: true,
            description: (
              <BodyText>
                This is equal to pulling the power cord, which may cause data
                loss or system corruption.
              </BodyText>
            ),
            messages: {
              fail: <>Failed to register force off job on {server.name}.</>,
              proceed: 'Force off',
              success: (
                <>Successfully registered force off job on {server.name}.</>
              ),
            },
            method: 'put',
          },
        );
      },
      render: () => (
        <BodyText color={MAP_TO_COLOUR.red} inheritColour noWrap>
          Force off
        </BodyText>
      ),
    };

    const reset: ServerOption = {
      disabled: () => off,
      onClick: () => {
        handleAction(
          confirm.current,
          `/server/${server.uuid}/reset`,
          `Reset server ${server.name}?`,
          {
            dangerous: true,
            description: (
              <Grid container spacing="1em">
                <Grid item width="100%">
                  <BodyText>
                    This is equal to holding the power button to force shut
                    down, followed by pushing the power button again to turn the
                    machine back on.
                  </BodyText>
                </Grid>
                <Grid item width="100%">
                  <BodyText>
                    Reset is usually used to access the boot menu when
                    you&apos;ve missed it in the live VNC connection.
                  </BodyText>
                </Grid>
              </Grid>
            ),
            messages: {
              fail: <>Failed to register reset job on {server.name}.</>,
              proceed: 'Reset',
              success: (
                <>Successfully registered reset join on {server.name}.</>
              ),
            },
            method: 'put',
          },
        );
      },
      render: () => (
        <BodyText color={MAP_TO_COLOUR.red} inheritColour noWrap>
          Reset
        </BodyText>
      ),
    };

    const powerOff: ServerOption = {
      disabled: () => off,
      onClick: () => {
        handleAction(
          confirm.current,
          `/command/stop-server/${server.uuid}`,
          `Power off server ${server.name}?`,
          {
            description: (
              <BodyText>
                This is equal to pushing the power button. If the server
                doesn&apos;t respond to the corresponding signals, you may have
                to manually shut it down.
              </BodyText>
            ),
            messages: {
              fail: <>Failed to register power off job on {server.name}.</>,
              proceed: 'Power off',
              success: (
                <>Successfully registered power off job on {server.name}.</>
              ),
            },
            method: 'put',
          },
        );
      },
      render: () => (
        <BodyText inheritColour noWrap>
          Power off
        </BodyText>
      ),
    };

    const powerOn: ServerOption = {
      disabled: () => !off,
      onClick: () => {
        handleAction(
          confirm.current,
          `/command/start-server/${server.uuid}`,
          `Power on server ${server.name}?`,
          {
            description: (
              <BodyText>This is equal to pushing the power button.</BodyText>
            ),
            messages: {
              fail: <>Failed to register power on job on {server.name}.</>,
              proceed: 'Power on',
              success: (
                <>Successfully registered power on job on {server.name}.</>
              ),
            },
            method: 'put',
          },
        );
      },
      render: () => (
        <BodyText inheritColour noWrap>
          Power on
        </BodyText>
      ),
    };

    ops['power on'] = powerOn;

    ops.reset = reset;

    ops['power off'] = powerOff;
    ops['force off'] = forceOff;

    return ops;
  }, [node.name, off, provisioning, server.name, server.uuid]);

  return (
    <MuiBox>
      <ButtonWithMenu<ServerOption>
        getItemDisabled={(key, value) => value.disabled?.call(null, key, value)}
        getItemHref={(key, value) => value.href?.call(null, key, value)}
        items={options}
        onItemClick={(key, value) => value.onClick?.call(null, key, value)}
        renderItem={(key, value) => value.render(key, value)}
        {...slotProps?.button}
      >
        <MuiMoreVertIcon
          fontSize={slotProps?.button?.slotProps?.button?.icon?.size}
        />
      </ButtonWithMenu>
      {confirmDialog}
    </MuiBox>
  );
};

export default ServerMenu;
