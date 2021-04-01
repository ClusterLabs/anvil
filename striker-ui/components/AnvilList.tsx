import { makeStyles } from '@material-ui/core/styles';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import Divider from '@material-ui/core/Divider';
import { BodyText } from './Text';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles(() => ({
  root: {
    width: '100%',
  },
  divider: {
    background: TEXT,
  },
}));

const AnvilList = ({ list }: { list: AnvilListItem[] }): JSX.Element => {
  const classes = useStyles();

  return (
    <List component="nav" className={classes.root} aria-label="mailbox folders">
      <Divider className={classes.divider} />
      {list.map((anvil) => {
        return (
          <ListItem button key={anvil.anvil_uuid}>
            <BodyText text={anvil.anvil_name} />
            <BodyText text={anvil.anvil_state} />
          </ListItem>
        );
      })}
    </List>
  );
};

export default AnvilList;
