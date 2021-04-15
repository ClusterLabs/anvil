import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';
import { List, Box, Divider, ListItem } from '@material-ui/core';
import {
  BLUE,
  PURPLE_OFF,
  RED_ON,
  TEXT,
  HOVER,
} from '../../lib/consts/DEFAULT_THEME';
import Anvil from './Anvil';

const useStyles = makeStyles(() => ({
  root: {
    width: '100%',
  },
  divider: {
    background: TEXT,
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
    case 'Optimal':
      return 'optimal';
    case 'Not Ready':
      return 'notReady';
    case 'Degraded':
      return 'degraded';
    default:
      return 'optimal';
  }
};

const AnvilList = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const classes = useStyles();

  return (
    <List component="nav" className={classes.root} aria-label="mailbox folders">
      {list.map((anvil) => {
        return (
          <>
            <Divider className={classes.divider} />
            <ListItem button className={classes.button} key={anvil.anvil_uuid}>
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
