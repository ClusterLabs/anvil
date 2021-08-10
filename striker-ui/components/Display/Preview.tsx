import { Dispatch, SetStateAction, useEffect, useState } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import IconButton from '@material-ui/core/IconButton';
import DesktopWindowsIcon from '@material-ui/icons/DesktopWindows';
import CropOriginal from '@material-ui/icons/Image';
import { Panel } from '../Panels';
import { BLACK, GREY, TEXT } from '../../lib/consts/DEFAULT_THEME';
import { HeaderText } from '../Text';

interface PreviewProps {
  setMode: Dispatch<SetStateAction<boolean>>;
  uuid: string;
  serverName: string | string[] | undefined;
}

const useStyles = makeStyles(() => ({
  displayBox: {
    padding: 0,
    paddingTop: '.7em',
    width: '100%',
  },
  fullScreenButton: {
    borderRadius: 8,
    backgroundColor: TEXT,
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
  fullScreenBox: {
    paddingLeft: '1em',
    padding: 0,
  },
  imageButton: {
    padding: 0,
    color: TEXT,
  },
  imageIcon: {
    borderRadius: 8,
    padding: 0,
    backgroundColor: GREY,
    fontSize: '8em',
  },
  previewImage: {
    width: '100%',
    height: '100%',
  },
}));

const Preview = ({ setMode, uuid, serverName }: PreviewProps): JSX.Element => {
  const classes = useStyles();
  const [preview, setPreview] = useState<string>();

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/get_server_screenshot?server_uuid=${uuid}`,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
            },
          },
        );
        const { screenshot } = await res.json();
        setPreview(screenshot);
      } catch {
        setPreview('');
      }
    })();
  }, [uuid]);

  return (
    <Panel>
      <Box flexGrow={1}>
        <HeaderText text={`Server: ${serverName}`} />
      </Box>
      <Box display="flex" className={classes.displayBox}>
        <Box>
          <IconButton
            className={classes.imageButton}
            style={{ color: BLACK }}
            component="span"
            onClick={() => setMode(false)}
          >
            {!preview ? (
              <CropOriginal className={classes.imageIcon} />
            ) : (
              <img
                alt=""
                key="preview"
                src={`data:image/png;base64,${preview}`}
                className={classes.previewImage}
              />
            )}
          </IconButton>
        </Box>
        <Box className={classes.fullScreenBox}>
          <IconButton
            className={classes.fullScreenButton}
            style={{ color: BLACK }}
            component="span"
            onClick={() => setMode(false)}
          >
            <DesktopWindowsIcon />
          </IconButton>
        </Box>
      </Box>
    </Panel>
  );
};

export default Preview;
