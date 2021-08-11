import { useContext } from 'react';
import { Box, Divider } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { Panel } from '../Panels';
import { HeaderText, BodyText } from '../Text';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import {
  DIVIDER,
  LARGE_MOBILE_BREAKPOINT,
} from '../../lib/consts/DEFAULT_THEME';
import processNetworkData from './processNetwork';
import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import Spinner from '../Spinner';

const useStyles = makeStyles((theme) => ({
  container: {
    width: '100%',
    overflow: 'auto',
    height: '32vh',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
      overflow: 'hidden',
    },
  },
  root: {
    paddingTop: '.7em',
    paddingBottom: '.7em',
  },
  noPaddingLeft: {
    paddingLeft: 0,
  },
  divider: {
    background: DIVIDER,
  },
  verticalDivider: {
    height: '3.5em',
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'optimal':
      return 'ok';
    case 'degraded':
      return 'warning';
    case 'down':
      return 'error';
    default:
      return 'warning';
  }
};

const Network = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const classes = useStyles();

  const { data, isLoading } = PeriodicFetch<AnvilNetwork>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_networks?anvil_uuid=${uuid}`,
  );

  const processed = processNetworkData(data);
  return (
    <Panel>
      <HeaderText text="Network" />
      {!isLoading ? (
        <Box className={classes.container}>
          {data &&
            processed.bonds.map((bond: ProcessedBond) => {
              return (
                <>
                  <Box
                    display="flex"
                    flexDirection="row"
                    width="100%"
                    className={classes.root}
                  >
                    <Box p={1} className={classes.noPaddingLeft}>
                      <Decorator colour={selectDecorator(bond.bond_state)} />
                    </Box>
                    <Box p={1} flexGrow={1} className={classes.noPaddingLeft}>
                      <BodyText text={bond.bond_name} />
                      <BodyText text={`${bond.bond_speed}Mbps`} />
                    </Box>
                    <Box display="flex" style={{ paddingTop: '.5em' }}>
                      {bond.hosts.map(
                        (host, index: number): JSX.Element => (
                          <>
                            <Box
                              p={1}
                              key={host.host_name}
                              style={{ paddingTop: 0, paddingBottom: 0 }}
                            >
                              <Box>
                                <BodyText
                                  text={host.host_name}
                                  selected={false}
                                />
                                <BodyText text={host.link.link_name} />
                              </Box>
                            </Box>
                            {index !== bond.hosts.length - 1 && (
                              <Divider
                                className={`${classes.divider} ${classes.verticalDivider}`}
                                orientation="vertical"
                                flexItem
                              />
                            )}
                          </>
                        ),
                      )}
                    </Box>
                  </Box>
                  <Divider className={classes.divider} />
                </>
              );
            })}
        </Box>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default Network;
