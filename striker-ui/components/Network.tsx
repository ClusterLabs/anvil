import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';
import Panel from './Panel';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { BLUE, GREY, TEXT, HOVER } from '../lib/consts/DEFAULT_THEME';
import processNetworkData from './processNetwork';

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
      {data &&
        processed.bonds.map((bond: ProcessedBond) => {
          return (
            <>
              <Box display="flex" flexDirection="row" width="100%">
                <Box p={1} className={classes.noPaddingLeft}>
                  <div
                    className={`${classes.decorator} ${
                      classes[selectDecorator('Started')]
                    }`}
                  />
                </Box>
                <Box p={1} flexGrow={1} className={classes.noPaddingLeft}>
                  <BodyText text={bond.bond_name} />
                  <BodyText text="Speed" />
                </Box>
                {bond.nodes.map(
                  (node): JSX.Element => (
                    <Box p={1} key={node.host_name}>
                      <Box>
                        <BodyText text={node.host_name} />
                        <BodyText text={node.link.link_name} />
                      </Box>
                    </Box>
                  ),
                )}
              </Box>
            </>
          );
        })}
    </Panel>
  );
};

export default Network;
