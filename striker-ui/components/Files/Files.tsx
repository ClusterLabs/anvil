import { Box, IconButton } from '@material-ui/core';
import AddIcon from '@material-ui/icons/Add';
import { makeStyles } from '@material-ui/styles';

import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';
import { Panel } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';

const useStyles = makeStyles(() => ({
  addFileButton: ICON_BUTTON_STYLE,
}));

const Files = (): JSX.Element => {
  const classes = useStyles();

  return (
    <Panel>
      <Box display="flex">
        <Box flexGrow={1}>
          <HeaderText text="Files" />
        </Box>
        <Box>
          <IconButton className={classes.addFileButton}>
            <AddIcon />
          </IconButton>
        </Box>
      </Box>
      <Spinner />
    </Panel>
  );
};

export default Files;
