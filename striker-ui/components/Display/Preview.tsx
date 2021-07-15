import { Dispatch, SetStateAction } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import IconButton from '@material-ui/core/IconButton';
import DesktopWindowsIcon from '@material-ui/icons/DesktopWindows';
import CropOriginal from '@material-ui/icons/Image';
import { Panel } from '../Panels';
import { BLACK, GREY, TEXT } from '../../lib/consts/DEFAULT_THEME';

interface PreviewProps {
  setMode: Dispatch<SetStateAction<boolean>>;
}

const useStyles = makeStyles(() => ({
  displayBox: {
    padding: 0,
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
}));

const Preview = ({ setMode }: PreviewProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Panel>
      <Box display="flex" className={classes.displayBox}>
        <Box>
          <IconButton
            className={classes.imageButton}
            style={{ color: BLACK }}
            component="span"
            onClick={() => setMode(false)}
          >
            <CropOriginal className={classes.imageIcon} />
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
