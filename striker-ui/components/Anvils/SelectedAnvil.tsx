import { useContext } from 'react';
import { Switch, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { HeaderText } from '../Text';
import { SELECTED_ANVIL } from '../../lib/consts/DEFAULT_THEME';
import anvilState from '../../lib/consts/ANVILS';
import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import putJSON from '../../lib/fetchers/putJSON';

const useStyles = makeStyles(() => ({
  root: {
    width: '100%',
    '&:hover $child': {
      backgroundColor: SELECTED_ANVIL,
    },
  },
  anvilName: {
    paddingLeft: 0,
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'optimal':
      return 'ok';
    case 'not_ready':
      return 'warning';
    case 'degraded':
      return 'error';
    default:
      return 'error';
  }
};

const isAnvilOn = (anvil: AnvilListItem): boolean =>
  !(
    anvil.hosts.findIndex(({ state }: AnvilStatusHost) => state !== 'off') ===
    -1
  );

const SelectedAnvil = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const classes = useStyles();

  const index = list.findIndex(
    (anvil: AnvilListItem) => anvil.anvil_uuid === uuid,
  );

  return (
    <Box display="flex" flexDirection="row" width="100%">
      {uuid !== '' && (
        <>
          <Box p={1}>
            <Decorator colour={selectDecorator(list[index].anvil_state)} />
          </Box>
          <Box p={1} flexGrow={1} className={classes.anvilName}>
            <HeaderText text={list[index].anvil_name} />
            <HeaderText
              text={
                anvilState.get(list[index].anvil_state) || 'State unavailable'
              }
            />
          </Box>
          <Box p={1}>
            <Switch
              checked={isAnvilOn(list[index])}
              onChange={() =>
                putJSON('/anvils/set_power', {
                  anvil_uuid: list[index].anvil_uuid,
                  is_on: !isAnvilOn(list[index]),
                })
              }
            />
          </Box>
        </>
      )}
    </Box>
  );
};

export default SelectedAnvil;
