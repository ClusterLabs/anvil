import { Grid, List, ListItem, Divider, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';
import Panel from './Panel';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { HeaderText, BodyText } from './Text';
import { BLUE, GREY, TEXT, HOVER } from '../lib/consts/DEFAULT_THEME';

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
  noPaddingLeft: {
    paddingLeft: 0,
  },
  decorator: {
    width: '20px',
    height: '100%',
    borderRadius: 2,
  },
  started: {
    backgroundColor: BLUE,
  },
  stopped: {
    backgroundColor: GREY,
  },
}));

const selectDecorator = (
  state: string,
): keyof ClassNameMap<'started' | 'stopped'> => {
  switch (state) {
    case 'Started':
      return 'started';
    case 'Stopped':
      return 'stopped';
    default:
      return 'stopped';
  }
};

const Servers = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilServers>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_servers?anvil_uuid=`,
    anvil?.anvil_uuid,
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
            {data &&
              data.servers.map((server: AnvilServer) => {
                return (
                  <>
                    <ListItem
                      button
                      className={classes.button}
                      key={server.server_uuid}
                    >
                      <Box display="flex" flexDirection="row" width="100%">
                        <Box p={1} className={classes.noPaddingLeft}>
                          <div
                            className={`${classes.decorator} ${
                              classes[selectDecorator(server.server_state)]
                            }`}
                          />
                        </Box>
                        <Box
                          p={1}
                          flexGrow={1}
                          className={classes.noPaddingLeft}
                        >
                          <BodyText text={server.server_name} />
                          <BodyText text={server.server_state} />
                        </Box>
                        {server.server_state === 'Started' && (
                          <Box p={1}>
                            <BodyText
                              text={`${anvil.nodes[0].node_name} | ${anvil.nodes[1].node_name}`}
                            />
                          </Box>
                        )}
                      </Box>
                    </ListItem>
                    <Divider className={classes.divider} />
                  </>
                );
              })}
          </List>
        </Grid>
      </Grid>
    </Panel>
  );
};

export default Servers;
