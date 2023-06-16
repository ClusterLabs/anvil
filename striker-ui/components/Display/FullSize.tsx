import {
  Close as CloseIcon,
  Keyboard as KeyboardIcon,
} from '@mui/icons-material';
import {
  Box,
  IconButton,
  IconButtonProps,
  Menu,
  MenuItem,
  styled,
  Typography,
} from '@mui/material';
import RFB from '@novnc/novnc/core/rfb';
import { useState, useRef, useEffect, FC, useCallback } from 'react';
import dynamic from 'next/dynamic';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { BLACK, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';

import ContainedButton from '../ContainedButton';
import { HeaderText } from '../Text';
import keyCombinations from './keyCombinations';
import { Panel } from '../Panels';
import putFetch from '../../lib/fetchers/putFetch';
import putFetchWithTimeout from '../../lib/fetchers/putFetchWithTimeout';
import Spinner from '../Spinner';
import useProtectedState from '../../hooks/useProtectedState';

const PREFIX = 'FullSize';

const classes = {
  displayBox: `${PREFIX}-displayBox`,
  spinnerBox: `${PREFIX}-spinnerBox`,
  closeButton: `${PREFIX}-closeButton`,
  keyboardButton: `${PREFIX}-keyboardButton`,
  closeBox: `${PREFIX}-closeBox`,
  buttonsBox: `${PREFIX}-buttonsBox`,
  keysItem: `${PREFIX}-keysItem`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.displayBox}`]: {
    width: '75vw',
    height: '75vh',
    paddingTop: '1em',
    paddingBottom: 0,
    paddingLeft: 0,
    paddingRight: 0,
  },

  [`& .${classes.spinnerBox}`]: {
    flexDirection: 'column',
    width: '75vw',
    height: '75vh',
    alignItems: 'center',
    justifyContent: 'center',
  },

  [`& .${classes.closeButton}`]: {
    borderRadius: 8,
    backgroundColor: RED,
    '&:hover': {
      backgroundColor: RED,
    },
  },

  [`& .${classes.keyboardButton}`]: {
    borderRadius: 8,
    backgroundColor: TEXT,
    '&:hover': {
      backgroundColor: TEXT,
    },
  },

  [`& .${classes.closeBox}`]: {
    paddingBottom: '1em',
    paddingLeft: '.7em',
    paddingRight: 0,
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

const CMD_VNC_PIPE_URL = `${API_BASE_URL}/command/vnc-pipe`;

const VncDisplay = dynamic(() => import('./VncDisplay'), { ssr: false });

type FullSizeOptionalProps = {
  onClickCloseButton?: IconButtonProps['onClick'];
};

type FullSizeProps = FullSizeOptionalProps & {
  serverUUID: string;
  serverName: string | string[] | undefined;
};

type VncConnectionProps = {
  protocol: string;
  forwardPort: number;
};

const FULL_SIZE_DEFAULT_PROPS: Required<
  Omit<FullSizeOptionalProps, 'onClickCloseButton'>
> &
  Pick<FullSizeOptionalProps, 'onClickCloseButton'> = {
  onClickCloseButton: undefined,
};

const FullSize: FC<FullSizeProps> = ({
  onClickCloseButton,
  serverUUID,
  serverName,
}): JSX.Element => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const rfb = useRef<typeof RFB>();
  const hostname = useRef<string | undefined>(undefined);
  const [vncConnection, setVncConnection] = useProtectedState<
    VncConnectionProps | undefined
  >(undefined);
  const [vncConnecting, setVncConnecting] = useProtectedState<boolean>(false);
  const [isError, setIsError] = useProtectedState<boolean>(false);

  const connectVnc = useCallback(async () => {
    if (vncConnection || vncConnecting) return;

    setVncConnecting(true);

    try {
      const res = await putFetchWithTimeout(
        CMD_VNC_PIPE_URL,
        {
          serverUuid: serverUUID,
          open: true,
        },
        120000,
      );

      setVncConnection(await res.json());
    } catch {
      setIsError(true);
    } finally {
      setVncConnecting(false);
    }
  }, [
    serverUUID,
    setIsError,
    setVncConnecting,
    setVncConnection,
    vncConnecting,
    vncConnection,
  ]);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      hostname.current = window.location.hostname;
    }

    connectVnc();
  }, [connectVnc]);

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>): void => {
    setAnchorEl(event.currentTarget);
  };

  const handleClickClose = async () => {
    await putFetch(CMD_VNC_PIPE_URL, { serverUuid: serverUUID });
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

  return (
    <Panel>
      <StyledDiv>
        <Box flexGrow={1}>
          <HeaderText text={`Server: ${serverName}`} />
        </Box>
        {vncConnection ? (
          <Box display="flex" className={classes.displayBox}>
            <VncDisplay
              rfb={rfb}
              url={`${vncConnection.protocol}://${hostname.current}:${vncConnection.forwardPort}`}
              viewOnly={false}
              focusOnClick={false}
              clipViewport={false}
              dragViewport={false}
              scaleViewport
              resizeSession
              showDotCursor={false}
              background=""
              qualityLevel={6}
              compressionLevel={2}
              onDisconnect={({ detail: { clean } }) => {
                if (!clean) {
                  setVncConnection(undefined);
                  connectVnc();
                }
              }}
            />
            <Box>
              <Box className={classes.closeBox}>
                <IconButton
                  className={classes.closeButton}
                  style={{ color: TEXT }}
                  component="span"
                  onClick={(
                    ...args: Parameters<
                      Exclude<IconButtonProps['onClick'], undefined>
                    >
                  ) => {
                    handleClickClose();
                    onClickCloseButton?.call(null, ...args);
                  }}
                >
                  <CloseIcon />
                </IconButton>
              </Box>
              <Box className={classes.closeBox}>
                <IconButton
                  className={classes.keyboardButton}
                  style={{ color: BLACK }}
                  component="span"
                  onClick={handleClick}
                >
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
            </Box>
          </Box>
        ) : (
          <Box display="flex" className={classes.spinnerBox}>
            {!isError ? (
              <>
                <HeaderText
                  text={`Establishing connection with ${serverName}`}
                />
                <HeaderText text="This may take a few minutes" />
                <Spinner />
              </>
            ) : (
              <>
                <Box style={{ paddingBottom: '2em' }}>
                  <HeaderText text="There was a problem connecting to the server, please try again" />
                </Box>
                <ContainedButton
                  onClick={() => {
                    setIsError(false);
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
