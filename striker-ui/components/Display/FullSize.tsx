import {
  Close as CloseIcon,
  Dashboard as DashboardIcon,
  Fullscreen as FullscreenIcon,
  Keyboard as KeyboardIcon,
} from '@mui/icons-material';
import { Box, styled, Typography } from '@mui/material';
import RFB from '@novnc/novnc/core/rfb';
import dynamic from 'next/dynamic';
import { useState, useEffect, FC, useMemo, useRef, useCallback } from 'react';
import { useCookies } from 'react-cookie';

import IconButton from '../IconButton';
import keyCombinations from './keyCombinations';
import Menu from '../Menu';
import MenuItem from '../MenuItem';
import { Panel, PanelHeader } from '../Panels';
import ServerMenu from '../ServerMenu';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
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

// Unit: seconds
const DEFAULT_VNC_RECONNECT_TIMER_START = 10;

const MAP_TO_WSCODE_MSG: Record<number, string> = {
  1000: 'in-use by another process?',
  1006: 'destination is down?',
};

const buildServerVncUrl = (host: string, serverUuid: string) =>
  `ws://${host}/ws/server/vnc/${serverUuid}`;

const FullSize: FC<FullSizeProps> = ({
  onClickCloseButton,
  serverUuid,
  serverName,
  vncReconnectTimerStart = DEFAULT_VNC_RECONNECT_TIMER_START,
}): JSX.Element => {
  const [cookies] = useCookies([`suiapi.vncerror.${serverUuid}`]);

  const isFirstRender = useIsFirstRender();

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const [rfbConnectArgs, setRfbConnectArgs] = useState<
    Partial<RfbConnectArgs> | undefined
  >(undefined);
  const [vncConnecting, setVncConnecting] = useState<boolean>(false);

  const [vncError, setVncError] = useState<boolean>(false);
  const [vncWsErrorMessage, setVncWsErrorMessage] = useState<
    string | undefined
  >();
  const [vncApiErrorMessage, setVncApiErrorMessage] = useState<
    string | undefined
  >();

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
      url: buildServerVncUrl(window.location.host, serverUuid),
    });
  }, [serverUuid]);

  const disconnectServerVnc = useCallback(() => {
    if (rfb?.current) {
      rfb.current.disconnect();
      rfb.current = null;
    }

    setRfbConnectArgs(undefined);
  }, []);

  const reconnectServerVnc = useCallback(() => {
    disconnectServerVnc();
    connectServerVnc();
  }, [connectServerVnc, disconnectServerVnc]);

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
    (event) => {
      const { detail } = event;
      const { clean } = detail;

      if (clean) return;

      setVncConnecting(false);
      setVncError(true);

      updateVncReconnectTimer();
    },
    [updateVncReconnectTimer],
  );

  const wsCloseEventHandler = useCallback(
    (event?: WebsockCloseEvent): void => {
      if (!event) {
        setVncWsErrorMessage(undefined);

        return;
      }

      const { code: wscode, reason } = event;

      let wsmsg = `ws: ${wscode}`;

      const guess = MAP_TO_WSCODE_MSG[wscode];

      if (guess) {
        wsmsg += ` (${guess})`;
      }

      if (reason) {
        wsmsg += `, ${reason}`;
      }

      setVncWsErrorMessage(wsmsg);

      const vncerror: APIError | undefined =
        cookies[`suiapi.vncerror.${serverUuid}`];

      if (!vncerror) {
        setVncApiErrorMessage(undefined);

        return;
      }

      const { code: apicode, message } = vncerror;

      setVncApiErrorMessage(`api: ${apicode}, ${message}`);
    },
    [cookies, serverUuid],
  );

  const showScreen = useMemo(
    () => !vncConnecting && !vncError,
    [vncConnecting, vncError],
  );

  const fullscreenElement = useMemo(
    () => (
      <Box>
        <IconButton
          onClick={() => {
            rfbScreen.current?.requestFullscreen();
          }}
        >
          <FullscreenIcon />
        </IconButton>
      </Box>
    ),
    [],
  );

  const keyboardMenuElement = useMemo(
    () => (
      <Box>
        <IconButton onClick={handleClickKeyboard}>
          <KeyboardIcon />
        </IconButton>
        <Menu
          muiMenuProps={{
            anchorEl,
            keepMounted: true,
            onClose: () => setAnchorEl(null),
          }}
          open={Boolean(anchorEl)}
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
      <Box>
        <IconButton
          onClick={(...args) => {
            disconnectServerVnc();
            onClickCloseButton?.call(null, ...args);
          }}
        >
          <CloseIcon />
        </IconButton>
      </Box>
    ),
    [disconnectServerVnc, onClickCloseButton],
  );

  const returnHomeElement = useMemo(
    () => (
      <Box>
        <IconButton
          onClick={() => {
            if (!window) return;

            disconnectServerVnc();

            window.location.assign('/');
          }}
        >
          <DashboardIcon />
        </IconButton>
      </Box>
    ),
    [disconnectServerVnc],
  );

  const vncToolbarElement = useMemo(
    () =>
      showScreen && (
        <>
          {fullscreenElement}
          {keyboardMenuElement}
          <ServerMenu
            serverName={serverName}
            serverState="running"
            serverUuid={serverUuid}
          />
          {returnHomeElement}
          {vncDisconnectElement}
        </>
      ),
    [
      fullscreenElement,
      keyboardMenuElement,
      returnHomeElement,
      serverName,
      serverUuid,
      showScreen,
      vncDisconnectElement,
    ],
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
            onWsClose={wsCloseEventHandler}
            rfb={rfb}
            rfbConnectArgs={rfbConnectArgs}
            rfbScreen={rfbScreen}
          />
        </Box>
        {!showScreen && (
          <Box display="flex" className={classes.spinnerBox} textAlign="center">
            {vncConnecting && (
              <>
                <HeaderText>Connecting to {serverName}.</HeaderText>
                <Spinner />
              </>
            )}
            {vncError && (
              <>
                <HeaderText>Can&apos;t connect to the server.</HeaderText>
                <BodyText>{vncApiErrorMessage}</BodyText>
                <BodyText>{vncWsErrorMessage}</BodyText>
                <HeaderText mt=".5em">
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

export default FullSize;
