import { useContext, useEffect } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import { List, Box, Divider, ListItem } from '@material-ui/core';
import {
  HOVER,
  DIVIDER,
  LARGE_MOBILE_BREAKPOINT,
} from '../../lib/consts/DEFAULT_THEME';
import Anvil from './Anvil';
import { AnvilContext } from '../AnvilContext';
import sortAnvils from './sortAnvils';
import Decorator, { Colours } from '../Decorator';

const useStyles = makeStyles((theme) => ({
  root: {
    width: '100%',
    overflow: 'auto',
    height: '30vh',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
      overflow: 'hidden',
    },
  },
  divider: {
    background: DIVIDER,
  },
  button: {
    '&:hover': {
      backgroundColor: HOVER,
    },
    paddingLeft: 0,
  },
  anvil: {
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
      return 'off';
  }
};

const AnvilList = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const { uuid, setAnvilUuid } = useContext(AnvilContext);
  const classes = useStyles();

  useEffect(() => {
    if (uuid === '') setAnvilUuid(sortAnvils(list)[0].anvil_uuid);
  }, [uuid, list, setAnvilUuid]);

  return (
    <List component="nav" className={classes.root} aria-label="mailbox folders">
      {sortAnvils(list).map((anvil) => {
        return (
          <>
            <Divider className={classes.divider} />
            <ListItem
              button
              className={classes.button}
              key={anvil.anvil_uuid}
              onClick={() => setAnvilUuid(anvil.anvil_uuid)}
            >
              <Box display="flex" flexDirection="row" width="100%">
                <Box p={1}>
                  <Decorator colour={selectDecorator(anvil.anvil_state)} />
                </Box>
                <Box p={1} flexGrow={1} className={classes.anvil}>
                  <Anvil anvil={anvil} />
                </Box>
              </Box>
            </ListItem>
          </>
        );
      })}
    </List>
  );
};

export default AnvilList;
