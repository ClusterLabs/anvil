import MuiCloseIcon from '@mui/icons-material/Close';
import MuiDashboardIcon from '@mui/icons-material/Dashboard';
import MuiFullscreenIcon from '@mui/icons-material/Fullscreen';
import MuiKeyboardIcon from '@mui/icons-material/Keyboard';
import MuiBox from '@mui/material/Box';
import MuiTypography from '@mui/material/Typography';
import styled from '@mui/material/styles/styled';
import RFB from '@novnc/novnc/core/rfb';
import dynamic from 'next/dynamic';
import { useState, useEffect, useMemo, useRef, useCallback } from 'react';
import { useCookies } from 'react-cookie';

import IconButton from '../IconButton';
import keyCombinations from './keyCombinations';
import Menu from '../Menu';
import MenuItem from '../MenuItem';
import { Panel, PanelHeader } from '../Panels';
import ServerMenu from '../ManageServer/ServerMenu';
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
const DEFAULT_VNC_RECONNECT_TIMER_START = 3;

const MAP_TO_WSCODE_MSG: Record<number, string> = {
  1000: 'in-use by another process?',
  1006: 'destination is down?',
};

const buildServerVncUrl = (host: string, server: string) =>
  `ws://${host}/ws/server/vnc/${server}`;

const FullSize = <Node extends NodeMinimum, Server extends ServerMinimum>(
  ...[props]: Parameters<FullSizeComponent<Node, Server>>
): ReturnType<FullSizeComponent<Node, Server>> => {
  const {
    node,
    onClickCloseButton,
    server,
    vncReconnectTimerStart = DEFAULT_VNC_RECONNECT_TIMER_START,
  } = props;

  const [cookies] = useCookies([`suiapi.vncerror.${server.uuid}`]);

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
      url: buildServerVncUrl(window.location.host, server.uuid),
    });
  }, [server.uuid]);

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
  const rfbDisconnectEventHandler = useCallback<
    Exclude<RfbConnectArgs['onDisconnect'], undefined>
  >(
    (event) => {
      const { clean } = event.detail;

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
        cookies[`suiapi.vncerror.${server.uuid}`];

      if (!vncerror) {
        setVncApiErrorMessage(undefined);

        return;
      }

      const { code: apicode, message } = vncerror;

      setVncApiErrorMessage(`api: ${apicode}, ${message}`);
    },
    [cookies, server.uuid],
  );

  const showScreen = useMemo(
    () => !vncConnecting && !vncError,
    [vncConnecting, vncError],
  );

  const fullscreenElement = useMemo(
    () => (
      <MuiBox>
        <IconButton
          onClick={() => {
            rfbScreen.current?.requestFullscreen();
          }}
        >
          <MuiFullscreenIcon />
        </IconButton>
      </MuiBox>
    ),
    [],
  );

  const keyboardMenuElement = useMemo(
    () => (
      <MuiBox>
        <IconButton onClick={handleClickKeyboard}>
          <MuiKeyboardIcon />
        </IconButton>
        <Menu
          open={Boolean(anchorEl)}
          slotProps={{
            menu: {
              anchorEl,
              keepMounted: true,
              onClose: () => setAnchorEl(null),
            },
          }}
        >
          {keyCombinations.map(({ keys, scans }) => (
            <MenuItem key={keys} onClick={() => handleSendKeys(scans)}>
              <MuiTypography variant="subtitle1">{keys}</MuiTypography>
            </MenuItem>
          ))}
        </Menu>
      </MuiBox>
    ),
    [anchorEl],
  );

  const vncDisconnectElement = useMemo(
    () => (
      <MuiBox>
        <IconButton
          onClick={(...args) => {
            disconnectServerVnc();
            onClickCloseButton?.call(null, ...args);
          }}
        >
          <MuiCloseIcon />
        </IconButton>
      </MuiBox>
    ),
    [disconnectServerVnc, onClickCloseButton],
  );

  const returnHomeElement = useMemo(
    () => (
      <MuiBox>
        <IconButton
          onClick={() => {
            if (!window) return;

            disconnectServerVnc();

            window.location.assign('/');
          }}
        >
          <MuiDashboardIcon />
        </IconButton>
      </MuiBox>
    ),
    [disconnectServerVnc],
  );

  const vncToolbarElement = useMemo(
    () => (
      <>
        {fullscreenElement}
        {keyboardMenuElement}
        <ServerMenu node={node} server={server} />
        {returnHomeElement}
        {vncDisconnectElement}
      </>
    ),
    [
      fullscreenElement,
      keyboardMenuElement,
      node,
      returnHomeElement,
      server,
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
        <HeaderText text={`Server: ${server.name}`} />
        {vncToolbarElement}
      </PanelHeader>
      <StyledDiv>
        <MuiBox
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
        </MuiBox>
        {!showScreen && (
          <MuiBox
            display="flex"
            className={classes.spinnerBox}
            textAlign="center"
          >
            {vncConnecting && (
              <>
                <HeaderText>Connecting to {server.name}.</HeaderText>
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
          </MuiBox>
        )}
      </StyledDiv>
    </Panel>
  );
};

export default FullSize;
