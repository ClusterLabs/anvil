import { makeStyles } from '@material-ui/core/styles';
import { List, ListItem, ListItemText, Divider } from '@material-ui/core';
import { TEXT } from '../lib/consts/DEFAULT_THEME';
import { BodyText } from './Text';

const useStyles = makeStyles(() => ({
  root: {
    width: '100%',
    '&:hover $child': {
      backgroundColor: '#00ff00',
    },
  },
  divider: {
    background: TEXT,
  },
  button: {
    '&:hover': {
      backgroundColor: '#F6F6E8',
    },
  },
}));

const AnvilList = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const classes = useStyles();

  return (
    <List component="nav" className={classes.root} aria-label="mailbox folders">
      <Divider className={classes.divider} />
      {list.map((anvil) => {
        return (
          <ListItem button key={anvil.anvil_uuid} className={classes.button}>
            <ListItemText
              primary={<BodyText text={anvil.anvil_name} />}
              secondary={<BodyText text={anvil.anvil_state} />}
            />
          </ListItem>
        );
      })}
    </List>
  );
};

export default AnvilList;
