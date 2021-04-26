import { Box, Divider } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';
import Panel from './Panel';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { BLUE, PURPLE_OFF, GREY } from '../lib/consts/DEFAULT_THEME';
import processNetworkData from './processNetwork';

const useStyles = makeStyles(() => ({
  container: {
    width: '100%',
    overflow: 'auto',
    height: '30vh',
  },
  root: {
    paddingTop: '10px',
    paddingBottom: '10px',
  },
  noPaddingLeft: {
    paddingLeft: 0,
  },
  divider: {
    background: GREY,
  },
  decorator: {
    width: '20px',
    height: '100%',
    borderRadius: 2,
  },
  optimal: {
    backgroundColor: BLUE,
  },
  degraded: {
    backgroundColor: PURPLE_OFF,
  },
}));

const selectDecorator = (
  state: string,
): keyof ClassNameMap<'optimal' | 'degraded'> => {
  switch (state) {
    case 'optimal':
      return 'optimal';
    case 'degraded':
      return 'degraded';
    default:
      return 'degraded';
  }
};

const Network = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilNetwork>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_network?anvil_uuid=`,
    anvil?.anvil_uuid,
  );

  const processed = processNetworkData(data);
  return (
    <Panel>
      <HeaderText text="Network" />
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
                    <div
                      className={`${classes.decorator} ${
                        classes[selectDecorator(bond.bond_state)]
                      }`}
                    />
                  </Box>
                  <Box p={1} flexGrow={1} className={classes.noPaddingLeft}>
                    <BodyText text={bond.bond_name} />
                    <BodyText text={`${bond.bond_speed}Mbps`} />
                  </Box>
                  {bond.nodes.map(
                    (node): JSX.Element => (
                      <Box p={1} key={node.host_name}>
                        <Box>
                          <BodyText text={node.host_name} selected={false} />
                          <BodyText text={node.link.link_name} />
                        </Box>
                      </Box>
                    ),
                  )}
                </Box>
                <Divider className={classes.divider} />
              </>
            );
          })}
      </Box>
    </Panel>
  );
};

export default Network;
