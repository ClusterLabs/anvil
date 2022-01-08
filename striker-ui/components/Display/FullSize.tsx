import { useState, useRef, useEffect, Dispatch, SetStateAction } from 'react';
import dynamic from 'next/dynamic';
import {
  Box,
  Button,
  IconButton,
  Menu,
  MenuItem,
  Typography,
} from '@mui/material';
import { styled } from '@mui/material/styles';
import CloseIcon from '@mui/icons-material/Close';
import KeyboardIcon from '@mui/icons-material/Keyboard';
import RFB from '@novnc/novnc/core/rfb';
import { Panel } from '../Panels';
import { BLACK, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';
import keyCombinations from './keyCombinations';
import putFetch from '../../lib/fetchers/putFetch';
import putFetchWithTimeout from '../../lib/fetchers/putFetchWithTimeout';
import { HeaderText } from '../Text';
import Spinner from '../Spinner';

const PREFIX = 'FullSize';

const classes = {
  displayBox: `${PREFIX}-displayBox`,
  spinnerBox: `${PREFIX}-spinnerBox`,
  closeButton: `${PREFIX}-closeButton`,
  keyboardButton: `${PREFIX}-keyboardButton`,
  closeBox: `${PREFIX}-closeBox`,
  buttonsBox: `${PREFIX}-buttonsBox`,
  keysItem: `${PREFIX}-keysItem`,
  buttonText: `${PREFIX}-buttonText`,
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

  [`& .${classes.buttonText}`]: {
    color: BLACK,
  },
}));

const VncDisplay = dynamic(() => import('./VncDisplay'), { ssr: false });

interface FullSizeProps {
  setMode: Dispatch<SetStateAction<boolean>>;
  uuid: string;
  serverName: string | string[] | undefined;
}

interface VncConnectionProps {
  protocol: string;
  forward_port: number;
}

const FullSize = ({
  setMode,
  uuid,
  serverName,
}: FullSizeProps): JSX.Element => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const rfb = useRef<typeof RFB>();
  const hostname = useRef<string | undefined>(undefined);
  const [vncConnection, setVncConnection] = useState<
    VncConnectionProps | undefined
  >(undefined);
  const [isError, setIsError] = useState<boolean>(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      hostname.current = window.location.hostname;
    }

    if (!vncConnection)
      (async () => {
        try {
          const res = await putFetchWithTimeout(
            `${process.env.NEXT_PUBLIC_API_URL}/manage_vnc_pipes`,
            {
              server_uuid: uuid,
              is_open: true,
            },
            120000,
          );
          setVncConnection(await res.json());
        } catch {
          setIsError(true);
        }
      })();
  }, [uuid, vncConnection, isError]);

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>): void => {
    setAnchorEl(event.currentTarget);
  };

  const handleClickClose = async () => {
    await putFetch(`${process.env.NEXT_PUBLIC_API_URL}/manage_vnc_pipes`, {
      server_uuid: uuid,
      is_open: false,
    });
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
              url={`${vncConnection.protocol}://${hostname.current}:${vncConnection.forward_port}`}
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
            />
            <Box>
              <Box className={classes.closeBox}>
                <IconButton
                  className={classes.closeButton}
                  style={{ color: TEXT }}
                  component="span"
                  onClick={() => {
                    handleClickClose();
                    setMode(true);
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
                  {keyCombinations.map(({ keys, scans }) => {
                    return (
                      <MenuItem
                        onClick={() => handleSendKeys(scans)}
                        className={classes.keysItem}
                        key={keys}
                      >
                        <Typography variant="subtitle1">{keys}</Typography>
                      </MenuItem>
                    );
                  })}
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
                <Button
                  variant="contained"
                  onClick={() => {
                    setIsError(false);
                  }}
                  style={{ textTransform: 'none' }}
                >
                  <Typography
                    className={classes.buttonText}
                    variant="subtitle1"
                  >
                    Reconnect
                  </Typography>
                </Button>
              </>
            )}
          </Box>
        )}
      </StyledDiv>
    </Panel>
  );
};

export default FullSize;
