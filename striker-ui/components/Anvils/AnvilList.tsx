import { useContext } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';
import { List, Box, Divider, ListItem } from '@material-ui/core';
import {
  BLUE,
  PURPLE_OFF,
  RED_ON,
  HOVER,
  DIVIDER,
} from '../../lib/consts/DEFAULT_THEME';
import Anvil from './Anvil';
import { AnvilContext } from '../AnvilContext';
import sortAnvils from './sortAnvils';

const useStyles = makeStyles(() => ({
  root: {
    width: '100%',
    overflow: 'auto',
    height: '30vh',
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

const AnvilList = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const { setAnvilUuid } = useContext(AnvilContext);
  const classes = useStyles();

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
                  <div
                    className={`${classes.decorator} ${
                      classes[selectDecorator(anvil.anvil_state)]
                    }`}
                  />
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
