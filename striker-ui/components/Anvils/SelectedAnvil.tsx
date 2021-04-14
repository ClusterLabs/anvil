import { useState } from 'react';
import { Switch, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { HeaderText } from '../Text';
import { BLUE } from '../../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles(() => ({
  root: {
    width: '100%',
    '&:hover $child': {
      backgroundColor: '#00ff00',
    },
  },
  anvilName: {
    paddingLeft: 0,
  },
  decorator: {
    width: '20px',
    height: '100%',
    backgroundColor: BLUE,
    borderRadius: 2,
  },
}));

const SelectedAnvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const classes = useStyles();
  const [checked, setChecked] = useState<boolean>(true);

  return (
    <Box display="flex" flexDirection="row" width="100%">
      <Box p={1}>
        <div className={classes.decorator} />
      </Box>
      <Box p={1} flexGrow={1} className={classes.anvilName}>
        <HeaderText text={anvil?.anvil_name} />
        <HeaderText text={anvil?.anvil_state || 'State unavailable'} />
      </Box>
      <Box p={1}>
        <Switch checked={checked} onChange={() => setChecked(!checked)} />
      </Box>
    </Box>
  );
};

export default SelectedAnvil;
