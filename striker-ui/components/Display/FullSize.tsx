import {
  Close as CloseIcon,
  Keyboard as KeyboardIcon,
} from '@mui/icons-material';
import {
  Box,
  IconButtonProps,
  Menu,
  MenuItem,
  styled,
  Typography,
} from '@mui/material';
import RFB from '@novnc/novnc/core/rfb';
import dynamic from 'next/dynamic';
import { useState, useEffect, FC, useMemo, useRef, useCallback } from 'react';

import { TEXT } from '../../lib/consts/DEFAULT_THEME';

import ContainedButton from '../ContainedButton';
import IconButton from '../IconButton';
import keyCombinations from './keyCombinations';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import useIsFirstRender from '../../hooks/useIsFirstRender';
import useProtectedState from '../../hooks/useProtectedState';

const PREFIX = 'FullSize';

const classes = {
  displayBox: `${PREFIX}-displayBox`,
  spinnerBox: `${PREFIX}-spinnerBox`,
  buttonsBox: `${PREFIX}-buttonsBox`,
  keysItem: `${PREFIX}-keysItem`,
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

  [`& .${classes.buttonsBox}`]: {
    paddingTop: 0,
  },

  [`& .${classes.keysItem}`]: {
    backgroundColor: TEXT,
    paddingRight: '3em',
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
}));

const VncDisplay = dynamic(() => import('./VncDisplay'), { ssr: false });

type FullSizeOptionalProps = {
  onClickCloseButton?: IconButtonProps['onClick'];
};

type FullSizeProps = FullSizeOptionalProps & {
  serverUUID: string;
  serverName: string | string[] | undefined;
};

const FULL_SIZE_DEFAULT_PROPS: Required<
  Omit<FullSizeOptionalProps, 'onClickCloseButton'>
> &
  Pick<FullSizeOptionalProps, 'onClickCloseButton'> = {
  onClickCloseButton: undefined,
};

const buildServerVncUrl = (hostname: string, serverUuid: string) =>
  `ws://${hostname}/ws/server/vnc/${serverUuid}`;

const FullSize: FC<FullSizeProps> = ({
  onClickCloseButton,
  serverUUID,
  serverName,
}): JSX.Element => {
  const isFirstRender = useIsFirstRender();

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);

  const [rfbConnectArgs, setRfbConnectArgs] = useProtectedState<
    RfbConnectArgs | undefined
  >(undefined);
  const [vncConnecting, setVncConnecting] = useProtectedState<boolean>(false);
  const [vncError, setVncError] = useProtectedState<boolean>(false);

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

  // 'connect' event emits when a connection successfully completes.
  const rfbConnectEventHandler = useCallback(() => {
    setVncConnecting(false);
  }, [setVncConnecting]);

  // 'disconnect' event emits when a connection fails,
  // OR when a user closes the existing connection.
  const rfbDisconnectEventHandler = useCallback(
    ({ detail: { clean } }) => {
      if (!clean) {
        setVncConnecting(false);
        setVncError(true);
      }
    },
    [setVncConnecting, setVncError],
  );

  const connectServerVnc = useCallback(() => {
    setVncConnecting(true);
    setVncError(false);

    setRfbConnectArgs({
      onConnect: rfbConnectEventHandler,
      onDisconnect: rfbDisconnectEventHandler,
      rfb,
      rfbScreen,
      url: buildServerVncUrl(window.location.hostname, serverUUID),
    });
  }, [
    rfbConnectEventHandler,
    rfbDisconnectEventHandler,
    serverUUID,
    setRfbConnectArgs,
    setVncConnecting,
    setVncError,
  ]);

  const disconnectServerVnc = useCallback(() => {
    setRfbConnectArgs(undefined);
  }, [setRfbConnectArgs]);

  const reconnectServerVnc = useCallback(() => {
    if (!rfb?.current) return;

    rfb.current.disconnect();
    rfb.current = null;

    connectServerVnc();
  }, [connectServerVnc]);

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
            <MenuItem
              onClick={() => handleSendKeys(scans)}
              className={classes.keysItem}
              key={keys}
            >
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
            rfb={rfb}
            rfbConnectPartialArgs={rfbConnectArgs}
            rfbScreen={rfbScreen}
          />
        </Box>
        {!showScreen && (
          <Box display="flex" className={classes.spinnerBox}>
            {vncConnecting && (
              <>
                <HeaderText>Connecting to {serverName}...</HeaderText>
                <Spinner />
              </>
            )}
            {vncError && (
              <>
                <Box style={{ paddingBottom: '2em' }}>
                  <HeaderText textAlign="center">
                    There was a problem connecting to the server, please try
                    again
                  </HeaderText>
                </Box>
                <ContainedButton
                  onClick={() => {
                    reconnectServerVnc();
                  }}
                >
                  Reconnect
                </ContainedButton>
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
