import { useContext } from 'react';
import { List, ListItem, Divider, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { Panel } from './Panels';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { HeaderText, BodyText } from './Text';
import { HOVER, DIVIDER } from '../lib/consts/DEFAULT_THEME';
import { AnvilContext } from './AnvilContext';
import serverState from '../lib/consts/SERVERS';
import Decorator, { Colours } from './Decorator';
import Spinner from './Spinner';
import hostsSanitizer from '../lib/sanitizers/hostsSanitizer';

const useStyles = makeStyles((theme) => ({
  root: {
    width: '100%',
    overflow: 'auto',
    height: '78vh',
    [theme.breakpoints.down('md')]: {
      height: '100%',
    },
  },
  divider: {
    background: DIVIDER,
  },
  verticalDivider: {
    height: '75%',
    paddingTop: '1em',
  },
  button: {
    '&:hover': {
      backgroundColor: HOVER,
    },
    paddingLeft: 0,
  },
  headerPadding: {
    paddingLeft: '.3em',
  },
  hostsBox: {
    padding: '1em',
    paddingRight: 0,
  },
  hostBox: {
    paddingTop: 0,
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'running':
      return 'ok';
    case 'shut off':
      return 'off';
    case 'crashed':
      return 'error';
    default:
      return 'warning';
  }
};

const Servers = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const classes = useStyles();

  const { data, isLoading } = PeriodicFetch<AnvilServers>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_servers?anvil_uuid=${uuid}`,
  );

  const anvilIndex = anvil.findIndex((a) => a.anvil_uuid === uuid);

  const filteredHosts = hostsSanitizer(anvil[anvilIndex]?.hosts);

  return (
    <Panel>
      <div className={classes.headerPadding}>
        <HeaderText text="Servers" />
      </div>
      {!isLoading ? (
        <Box className={classes.root}>
          <List component="nav">
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
                        <Box p={1}>
                          <Decorator
                            colour={selectDecorator(server.server_state)}
                          />
                        </Box>
                        <Box p={1} flexGrow={1}>
                          <BodyText text={server.server_name} />
                          <BodyText
                            text={
                              serverState.get(server.server_state) ||
                              'Not Available'
                            }
                          />
                        </Box>
                        <Box display="flex" className={classes.hostsBox}>
                          {server.server_state !== 'shut off' &&
                            server.server_state !== 'crashed' &&
                            filteredHosts.map(
                              (
                                host: AnvilStatusHost,
                                index: number,
                              ): JSX.Element => (
                                <>
                                  <Box
                                    p={1}
                                    key={host.host_uuid}
                                    className={classes.hostBox}
                                  >
                                    <BodyText
                                      text={host.host_name}
                                      selected={
                                        server.server_host_uuid ===
                                        host.host_uuid
                                      }
                                    />
                                  </Box>
                                  {index !== filteredHosts.length - 1 && (
                                    <Divider
                                      className={`${classes.divider} ${classes.verticalDivider}`}
                                      orientation="vertical"
                                    />
                                  )}
                                </>
                              ),
                            )}
                        </Box>
                      </Box>
                    </ListItem>
                    <Divider className={classes.divider} />
                  </>
                );
              })}
          </List>
        </Box>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default Servers;
