import {
  Close as CloseIcon,
  Keyboard as KeyboardIcon,
} from '@mui/icons-material';
import { Box, IconButtonProps, Menu, styled, Typography } from '@mui/material';
import RFB from '@novnc/novnc/core/rfb';
import dynamic from 'next/dynamic';
import { useState, useEffect, FC, useMemo, useRef, useCallback } from 'react';

import IconButton from '../IconButton';
import keyCombinations from './keyCombinations';
import MenuItem from '../MenuItem';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import useIsFirstRender from '../../hooks/useIsFirstRender';

const PREFIX = 'FullSize';

const classes = {
  displayBox: `${PREFIX}-displayBox`,
  spinnerBox: `${PREFIX}-spinnerBox`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.displayBox}`]: {
    width: '75vw',
    height: '75vh',
  },

  [`& .${classes.spinnerBox}`]: {
    flexDirection: 'column',
    width: '75vw',
    height: '75vh',
    alignItems: 'center',
    justifyContent: 'center',
  },
}));

const VncDisplay = dynamic(() => import('./VncDisplay'), { ssr: false });

type FullSizeOptionalProps = {
  onClickCloseButton?: IconButtonProps['onClick'];
};

type FullSizeProps = FullSizeOptionalProps & {
  vncReconnectTimerStart: number;
  serverUUID: string;
  serverName: string | string[] | undefined;
};

const FULL_SIZE_DEFAULT_PROPS: Required<
  Omit<FullSizeOptionalProps, 'onClickCloseButton'>
> &
  Pick<FullSizeOptionalProps, 'onClickCloseButton'> = {
  onClickCloseButton: undefined,
};
// Unit: seconds
const DEFAULT_VNC_RECONNECT_TIMER_START = 5;

const buildServerVncUrl = (hostname: string, serverUuid: string) =>
  `ws://${hostname}/ws/server/vnc/${serverUuid}`;

const FullSize: FC<FullSizeProps> = ({
  onClickCloseButton,
  serverUUID,
  serverName,
  vncReconnectTimerStart = DEFAULT_VNC_RECONNECT_TIMER_START,
}): JSX.Element => {
  const isFirstRender = useIsFirstRender();

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const [rfbConnectArgs, setRfbConnectArgs] = useState<
    Partial<RfbConnectArgs> | undefined
  >(undefined);
  const [vncConnecting, setVncConnecting] = useState<boolean>(false);
  const [vncError, setVncError] = useState<boolean>(false);
  const [vncReconnectTimer, setVncReconnectTimer] = useState<number>(
    vncReconnectTimerStart,
  );

  const rfb = useRef<typeof RFB | null>(null);
  const rfbScreen = useRef<HTMLDivElement | null>(null);

  const handleClickKeyboard = (
    event: React.MouseEvent<HTMLButtonElement>,
  ): void => {
    setAnchorEl(event.currentTarget);
  };

  const handleSendKeys = (scans: string[]) => {
    if (rfb.current) {
      if (!scans.length) rfb.current.sendCtrlAltDel();
      else {
        // Send pressing keys
        for (let i = 0; i <= scans.length - 1; i += 1) {
          rfb.current.sendKey(scans[i], 1);
        }

        // Send releasing keys in reverse order
        for (let i = scans.length - 1; i >= 0; i -= 1) {
          rfb.current.sendKey(scans[i], 0);
        }
      }
      setAnchorEl(null);
    }
  };

  const connectServerVnc = useCallback(() => {
    setVncConnecting(true);
    setVncError(false);

    setRfbConnectArgs({
      url: buildServerVncUrl(window.location.hostname, serverUUID),
    });
  }, [serverUUID]);

  const disconnectServerVnc = useCallback(() => {
    setRfbConnectArgs(undefined);
  }, []);

  const reconnectServerVnc = useCallback(() => {
    if (!rfb?.current) return;

    rfb.current.disconnect();
    rfb.current = null;

    connectServerVnc();
  }, [connectServerVnc]);

  const updateVncReconnectTimer = useCallback((): void => {
    const intervalId = setInterval((): void => {
      setVncReconnectTimer((previous) => {
        const current = previous - 1;

        if (current < 1) {
          clearInterval(intervalId);
        }

        return current;
      });
    }, 1000);
  }, []);

  // 'connect' event emits when a connection successfully completes.
  const rfbConnectEventHandler = useCallback(() => {
    setVncConnecting(false);
  }, []);

  // 'disconnect' event emits when a connection fails,
  // OR when a user closes the existing connection.
  const rfbDisconnectEventHandler = useCallback(
    ({ detail: { clean } }) => {
      if (!clean) {
        setVncConnecting(false);
        setVncError(true);

        updateVncReconnectTimer();
      }
    },
    [updateVncReconnectTimer],
  );

  const showScreen = useMemo(
    () => !vncConnecting && !vncError,
    [vncConnecting, vncError],
  );

  const keyboardMenuElement = useMemo(
    () => (
      <Box>
        <IconButton onClick={handleClickKeyboard}>
          <KeyboardIcon />
        </IconButton>
        <Menu
          anchorEl={anchorEl}
          keepMounted
          open={Boolean(anchorEl)}
          onClose={() => setAnchorEl(null)}
        >
          {keyCombinations.map(({ keys, scans }) => (
            <MenuItem key={keys} onClick={() => handleSendKeys(scans)}>
              <Typography variant="subtitle1">{keys}</Typography>
            </MenuItem>
          ))}
        </Menu>
      </Box>
    ),
    [anchorEl],
  );

  const vncDisconnectElement = useMemo(
    () => (
      <IconButton
        onClick={(...args) => {
          disconnectServerVnc();
          onClickCloseButton?.call(null, ...args);
        }}
        variant="redcontained"
      >
        <CloseIcon />
      </IconButton>
    ),
    [disconnectServerVnc, onClickCloseButton],
  );

  const vncToolbarElement = useMemo(
    () =>
      showScreen && (
        <>
          {keyboardMenuElement}
          {vncDisconnectElement}
        </>
      ),
    [keyboardMenuElement, showScreen, vncDisconnectElement],
  );

  useEffect(() => {
    if (vncReconnectTimer === 0) {
      setVncReconnectTimer(vncReconnectTimerStart);

      reconnectServerVnc();
    }
  }, [reconnectServerVnc, vncReconnectTimer, vncReconnectTimerStart]);

  useEffect(() => {
    if (isFirstRender) {
      connectServerVnc();
    }
  }, [connectServerVnc, isFirstRender]);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text={`Server: ${serverName}`} />
        {vncToolbarElement}
      </PanelHeader>
      <StyledDiv>
        <Box
          display={showScreen ? 'flex' : 'none'}
          className={classes.displayBox}
        >
          <VncDisplay
            onConnect={rfbConnectEventHandler}
            onDisconnect={rfbDisconnectEventHandler}
            rfb={rfb}
            rfbConnectArgs={rfbConnectArgs}
            rfbScreen={rfbScreen}
          />
        </Box>
        {!showScreen && (
          <Box display="flex" className={classes.spinnerBox}>
            {vncConnecting && (
              <>
                <HeaderText textAlign="center">
                  Connecting to {serverName}.
                </HeaderText>
                <Spinner />
              </>
            )}
            {vncError && (
              <>
                <HeaderText textAlign="center">
                  There was a problem connecting to the server.
                </HeaderText>
                <HeaderText textAlign="center" mt="1em">
                  Retrying in {vncReconnectTimer}.
                </HeaderText>
              </>
            )}
          </Box>
        )}
      </StyledDiv>
    </Panel>
  );
};

FullSize.defaultProps = FULL_SIZE_DEFAULT_PROPS;

export default FullSize;
