import { Box, Switch } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';

import InnerPanel from '../InnerPanel';
import { ProgressBar } from '../Bars';
import { BodyText } from '../Text';
import PanelHeader from '../PanelHeader';
import { BLUE, RED_ON, TEXT, PURPLE_OFF } from '../../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles(() => ({
  state: {
    paddingLeft: '10px',
    paddingRight: '10px',
    paddingTop: '15px',
  },
  bar: {
    paddingLeft: '10px',
    paddingRight: '10px',
  },
  label: {
    paddingTop: '5px',
  },
  decorator: {
    width: '20px',
    height: '100%',
    borderRadius: 2,
  },
  decoratorBox: {
    paddingRight: '5px',
  },
  ready: {
    backgroundColor: BLUE,
  },
  onAccessible: {
    backgroundColor: PURPLE_OFF,
  },
  off: {
    backgroundColor: TEXT,
  },
  unknown: {
    backgroundColor: RED_ON,
  },
}));

const selectDecorator = (
  state: string,
): keyof ClassNameMap<'unknown' | 'off' | 'onAccessible' | 'ready'> => {
  switch (state) {
    case 'ready':
      return 'ready';
    case 'off':
      return 'off';
    case 'accessible':
    case 'on':
      return 'onAccessible';
    default:
      return 'unknown';
  }
};

const AnvilNode = ({
  node,
}: {
  node: Array<AnvilStatusNode & AnvilListItemNode>;
}): JSX.Element => {
  const classes = useStyles();
  return (
    <>
      {node &&
        node.map(
          (n): JSX.Element => {
            return (
              <InnerPanel key={n.node_uuid}>
                <PanelHeader>
                  <Box display="flex" width="100%">
                    <Box flexGrow={1}>
                      <BodyText text={n.node_name} />
                    </Box>
                    <Box className={classes.decoratorBox}>
                      <div
                        className={`${classes.decorator} ${
                          classes[selectDecorator(n.state)]
                        }`}
                      />
                    </Box>
                    <Box>
                      <BodyText text={n.state} />
                    </Box>
                  </Box>
                </PanelHeader>
                <Box display="flex" className={classes.state}>
                  <Box className={classes.label}>
                    <BodyText text="Power: " />
                  </Box>
                  <Box flexGrow={1}>
                    <Switch checked />
                  </Box>
                  <Box className={classes.label}>
                    <BodyText text="Member: " />
                  </Box>
                  <Box>
                    <Switch checked />
                  </Box>
                </Box>
                {n.state !== 'ready' && (
                  <>
                    <Box display="flex" width="100%" className={classes.state}>
                      <Box flexGrow={1}>
                        <BodyText text={`State: ${n.state}`} />
                      </Box>
                      <Box>
                        <BodyText text={n.state_message} />
                      </Box>
                    </Box>
                    <Box display="flex" width="100%" className={classes.bar}>
                      <Box flexGrow={1}>
                        <ProgressBar progressPercentage={n.state_percent} />
                      </Box>
                    </Box>
                  </>
                )}
              </InnerPanel>
            );
          },
        )}
    </>
  );
};

export default AnvilNode;
