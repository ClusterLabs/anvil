import { Dispatch, SetStateAction } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import CloseIcon from '@material-ui/icons/Close';
import IconButton from '@material-ui/core/IconButton';
import VncDisplay from './VncDisplay';
import { Panel } from '../Panels';
import { RED, TEXT } from '../../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles(() => ({
  displayBox: {
    paddingTop: '1em',
    paddingBottom: 0,
  },
  closeButton: {
    borderRadius: 8,
    backgroundColor: RED,
    '&:hover': {
      backgroundColor: RED,
    },
  },
  closeBox: {
    paddingLeft: '.7em',
    paddingRight: 0,
  },
}));

interface PreviewProps {
  setMode: Dispatch<SetStateAction<boolean>>;
}

const FullSize = ({ setMode }: PreviewProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Panel>
      <Box display="flex" className={classes.displayBox}>
        <Box>
          <VncDisplay
            url="wss://spain.cdot.systems:5000/"
            style={{
              width: '75vw',
              height: '80vh',
            }}
          />
        </Box>
        <Box className={classes.closeBox}>
          <IconButton
            className={classes.closeButton}
            style={{ color: TEXT }}
            aria-label="upload picture"
            component="span"
            onClick={() => setMode(true)}
          >
            <CloseIcon />
          </IconButton>
        </Box>
      </Box>
    </Panel>
  );
};

export default FullSize;
