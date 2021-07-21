import { useState, useRef, useEffect, Dispatch, SetStateAction } from 'react';
import { RFB } from 'novnc-node';
import { Box, Menu, MenuItem, Typography, Button } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import CloseIcon from '@material-ui/icons/Close';
import KeyboardIcon from '@material-ui/icons/Keyboard';
import IconButton from '@material-ui/core/IconButton';
import VncDisplay from './VncDisplay';
import { Panel } from '../Panels';
import { BLACK, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';
import keyCombinations from './keyCombinations';
import putFetch from '../../lib/fetchers/putFetch';
import putFetchWithTimeout from '../../lib/fetchers/putFetchWithTimeout';
import { HeaderText } from '../Text';
import Spinner from '../Spinner';

const useStyles = makeStyles(() => ({
  displayBox: {
    paddingTop: '1em',
    paddingBottom: 0,
  },
  spinnerBox: {
    flexDirection: 'column',
    width: '75vw',
    height: '75vh',
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeButton: {
    borderRadius: 8,
    backgroundColor: RED,
    '&:hover': {
      backgroundColor: RED,
    },
  },
  keyboardButton: {
    borderRadius: 8,
    backgroundColor: TEXT,
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
  closeBox: {
    paddingBottom: '1em',
    paddingLeft: '.7em',
    paddingRight: 0,
  },
  buttonsBox: {
    paddingTop: 0,
  },
  keysItem: {
    backgroundColor: TEXT,
    paddingRight: '3em',
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
  buttonText: {
    color: BLACK,
  },
}));

interface PreviewProps {
  setMode: Dispatch<SetStateAction<boolean>>;
  uuid: string;
  serverName: string | string[] | undefined;
}

interface VncConnectionProps {
  protocol: string;
  forward_port: number;
}

const FullSize = ({ setMode, uuid, serverName }: PreviewProps): JSX.Element => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const rfb = useRef<typeof RFB>(undefined);
  const hostname = useRef<string | undefined>(undefined);
  const [vncConnection, setVncConnection] = useState<
    VncConnectionProps | undefined
  >(undefined);
  const [isError, setIsError] = useState<boolean>(false);
  const [displaySize] = useState<{
    width: string;
    height: string;
  }>({ width: '75%', height: '80%' });
  const classes = useStyles();

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
        scans.forEach((scan) => {
          rfb.current.sendKey(scan, 1);
        });

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
      <Box flexGrow={1}>
        <HeaderText text={`Server: ${serverName}`} />
      </Box>

      <Box display="flex" className={classes.displayBox}>
        {vncConnection ? (
          <>
            <Box>
              <VncDisplay
                rfb={rfb}
                url={`${vncConnection.protocol}://${hostname.current}:${vncConnection.forward_port}`}
                style={displaySize}
              />
            </Box>
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
          </>
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
      </Box>
    </Panel>
  );
};

export default FullSize;
