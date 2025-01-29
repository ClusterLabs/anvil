import { Box, Divider, styled } from '@mui/material';
import { useContext, useState } from 'react';

import {
  DIVIDER,
  LARGE_MOBILE_BREAKPOINT,
} from '../../lib/consts/DEFAULT_THEME';

import { AnvilContext } from '../AnvilContext';
import Decorator, { Colours } from '../Decorator';
import { Panel } from '../Panels';
import processNetworkData from './processNetwork';
import Spinner from '../Spinner';
import { HeaderText, BodyText } from '../Text';
import useFetch from '../../hooks/useFetch';

const PREFIX = 'Network';

const classes = {
  container: `${PREFIX}-container`,
  root: `${PREFIX}-root`,
  noPaddingLeft: `${PREFIX}-noPaddingLeft`,
  divider: `${PREFIX}-divider`,
  verticalDivider: `${PREFIX}-verticalDivider`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.container}`]: {
    width: '100%',
    overflow: 'auto',
    height: '32vh',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
      overflow: 'hidden',
    },
  },

  [`& .${classes.root}`]: {
    paddingTop: '.7em',
    paddingBottom: '.7em',
  },

  [`& .${classes.noPaddingLeft}`]: {
    paddingLeft: 0,
  },

  [`& .${classes.divider}`]: {
    backgroundColor: DIVIDER,
  },

  [`& .${classes.verticalDivider}`]: {
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

  const [processed, setProcessed] = useState<ProcessedNetwork | undefined>();

  const { loading } = useFetch<AnvilNetwork>(`/anvil/${uuid}/network`, {
    onSuccess: (data) => {
      setProcessed(processNetworkData(data));
    },
    periodic: true,
  });

  return (
    <Panel>
      <StyledDiv>
        <HeaderText text="Network" />
        {!loading ? (
          <Box className={classes.container}>
            {processed &&
              processed.bonds.map((bond: ProcessedBond) => (
                <>
                  <Box
                    className={classes.root}
                    display="flex"
                    flexDirection="row"
                    width="100%"
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
              ))}
          </Box>
        ) : (
          <Spinner />
        )}
      </StyledDiv>
    </Panel>
  );
};

export default Network;
