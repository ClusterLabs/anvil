import { Grid, List, ListItem, ListItemText } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import Panel from './Panel';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { TEXT } from '../lib/consts/DEFAULT_THEME';
import { HeaderText, BodyText } from './Text';

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

const Servers = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilServers>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_servers?anvil_uuid=`,
    anvil.anvil_uuid,
  );

  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Servers" />
        </Grid>
        <Grid item xs={12}>
          <List
            component="nav"
            className={classes.root}
            aria-label="mailbox folders"
          >
            <ListItem button className={classes.button}>
              <ListItemText
                primary={<BodyText text={anvil.anvil_name} />}
                secondary={<BodyText text={data.servers[0].server_name} />}
              />
            </ListItem>
          </List>
        </Grid>
      </Grid>
    </Panel>
  );
};

export default Servers;
