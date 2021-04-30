import { useContext } from 'react';
import { List, ListItem, Divider, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';
import { Panel } from './Panels';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { HeaderText, BodyText } from './Text';
import {
  BLUE,
  GREY,
  HOVER,
  DIVIDER,
  PURPLE_OFF,
  RED_ON,
} from '../lib/consts/DEFAULT_THEME';
import { AnvilContext } from './AnvilContext';
import serverState from '../lib/consts/SERVERS';

const useStyles = makeStyles((theme) => ({
  root: {
    width: '100%',
    overflow: 'auto',
    height: '80vh',
    [theme.breakpoints.down('md')]: {
      height: '100%',
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
  noPaddingLeft: {
    paddingLeft: 0,
  },
  decorator: {
    width: '20px',
    height: '100%',
    borderRadius: 2,
  },
  running: {
    backgroundColor: BLUE,
  },
  shut_off: {
    backgroundColor: GREY,
  },
  crashed: {
    backgroundColor: RED_ON,
  },
  warning: {
    backgroundColor: PURPLE_OFF,
  },
}));

const selectDecorator = (
  state: string,
): keyof ClassNameMap<'running' | 'shut_off' | 'crashed' | 'warning'> => {
  switch (state) {
    case 'running':
      return 'running';
    case 'shut_off':
      return 'shut_off';
    case 'crashed':
      return 'crashed';
    default:
      return 'warning';
  }
};

const Servers = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilServers>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_servers?anvil_uuid=`,
    uuid,
  );
  return (
    <Panel>
      <HeaderText text="Servers" />
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
                      <Box p={1} className={classes.noPaddingLeft}>
                        <div
                          className={`${classes.decorator} ${
                            classes[selectDecorator(server.server_state)]
                          }`}
                        />
                      </Box>
                      <Box p={1} flexGrow={1} className={classes.noPaddingLeft}>
                        <BodyText text={server.server_name} />
                        <BodyText
                          text={
                            serverState.get(server.server_state) ||
                            'Not Available'
                          }
                        />
                      </Box>
                      {server.server_state !== 'shut_off' &&
                        server.server_state !== 'crashed' &&
                        anvil[
                          anvil.findIndex((a) => a.anvil_uuid === uuid)
                        ].nodes.map(
                          (
                            node: AnvilListItemNode,
                            index: number,
                          ): JSX.Element => (
                            <Box p={1} key={node.node_uuid}>
                              <BodyText
                                text={node.node_name}
                                selected={server.server_host_index === index}
                              />
                            </Box>
                          ),
                        )}
                    </Box>
                  </ListItem>
                  <Divider className={classes.divider} />
                </>
              );
            })}
        </List>
      </Box>
    </Panel>
  );
};

export default Servers;
