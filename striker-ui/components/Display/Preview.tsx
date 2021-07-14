import { Dispatch, SetStateAction } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import IconButton from '@material-ui/core/IconButton';
import DesktopWindowsIcon from '@material-ui/icons/DesktopWindows';
import { Panel } from '../Panels';
import { BLACK, TEXT } from '../../lib/consts/DEFAULT_THEME';

interface PreviewProps {
  setMode: Dispatch<SetStateAction<boolean>>;
}

const useStyles = makeStyles(() => ({
  displayBox: {
    paddingTop: '1em',
    paddingBottom: 0,
  },
  fullScreenButton: {
    borderRadius: 8,
    backgroundColor: TEXT,
    '&:hover': {
      backgroundColor: TEXT,
    },
  },
  fullScreenBox: {
    paddingLeft: '.7em',
    paddingRight: 0,
  },
}));

const Preview = ({ setMode }: PreviewProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Panel>
      <Box display="flex" className={classes.displayBox}>
        <Box className={classes.fullScreenBox}>
          <IconButton
            className={classes.fullScreenButton}
            style={{ color: BLACK }}
            aria-label="upload picture"
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
