import { useState } from 'react';
import { Switch, Box } from '@material-ui/core';
import { ClassNameMap } from '@material-ui/styles';
import { makeStyles } from '@material-ui/core/styles';
import { HeaderText } from '../Text';
import { BLUE, PURPLE_OFF, RED_ON } from '../../lib/consts/DEFAULT_THEME';
import anvilState from './CONSTS';

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
    borderRadius: 2,
  },
  optimal: {
    backgroundColor: BLUE,
  },
  notReady: {
    backgroundColor: PURPLE_OFF,
  },
  degraded: {
    backgroundColor: RED_ON,
  },
}));

const selectDecorator = (
  state: string,
): keyof ClassNameMap<'optimal' | 'notReady' | 'degraded'> => {
  switch (state) {
    case 'optimal':
      return 'optimal';
    case 'not_ready':
      return 'notReady';
    case 'degraded':
      return 'degraded';
    default:
      return 'optimal';
  }
};

const SelectedAnvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const classes = useStyles();
  const [checked, setChecked] = useState<boolean>(true);

  return (
    <Box display="flex" flexDirection="row" width="100%">
      <Box p={1}>
        <div
          className={`${classes.decorator} ${
            classes[selectDecorator(anvil.anvil_state)]
          }`}
        />
      </Box>
      <Box p={1} flexGrow={1} className={classes.anvilName}>
        <HeaderText text={anvil?.anvil_name} />
        <HeaderText
          text={anvilState.get(anvil.anvil_state) || 'State unavailable'}
        />
      </Box>
      <Box p={1}>
        <Switch checked={checked} onChange={() => setChecked(!checked)} />
      </Box>
    </Box>
  );
};

export default SelectedAnvil;
