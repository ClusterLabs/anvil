import { Box, Switch } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { InnerPanel, PanelHeader } from '../Panels';
import { ProgressBar } from '../Bars';
import { BodyText } from '../Text';
import nodeState from '../../lib/consts/NODES';
import Decorator, { Colours } from '../Decorator';

import putJSON from '../../lib/fetchers/putJSON';

const useStyles = makeStyles((theme) => ({
  root: {
    overflow: 'auto',
    height: '28vh',
    paddingLeft: '.3em',
    [theme.breakpoints.down('md')]: {
      height: '100%',
      overflow: 'hidden',
    },
  },
  state: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
    paddingTop: '1em',
  },
  bar: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },
  header: {
    paddingTop: '.3em',
    paddingRight: '.7em',
  },
  label: {
    paddingTop: '.3em',
  },
  decoratorBox: {
    paddingRight: '.3em',
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'ready':
      return 'ok';
    case 'off':
      return 'off';
    case 'accessible':
    case 'on':
      return 'warning';
    default:
      return 'error';
  }
};

const AnvilNode = ({
  nodes,
}: {
  nodes: Array<AnvilStatusNode & AnvilListItemNode>;
}): JSX.Element => {
  const classes = useStyles();
  return (
    <Box className={classes.root}>
      {nodes &&
        nodes.map(
          (node): JSX.Element => {
            return (
              <InnerPanel key={node.node_uuid}>
                <PanelHeader>
                  <Box display="flex" width="100%" className={classes.header}>
                    <Box flexGrow={1}>
                      <BodyText text={node.node_name} />
                    </Box>
                    <Box className={classes.decoratorBox}>
                      <Decorator colour={selectDecorator(node.state)} />
                    </Box>
                    <Box>
                      <BodyText
                        text={nodeState.get(node.state) || 'Not Available'}
                      />
                    </Box>
                  </Box>
                </PanelHeader>
                <Box display="flex" className={classes.state}>
                  <Box className={classes.label}>
                    <BodyText text="Power: " />
                  </Box>
                  <Box flexGrow={1}>
                    <Switch
                      checked={node.state === 'ready'}
                      onChange={() =>
                        putJSON('/anvils/set_power', {
                          host_uuid: node.node_uuid,
                          is_on: !(node.state === 'ready'),
                        })
                      }
                    />
                  </Box>
                  <Box className={classes.label}>
                    <BodyText text="Member: " />
                  </Box>
                  <Box>
                    <Switch
                      checked={node.state === 'ready'}
                      disabled={!node.removable}
                      onChange={() =>
                        putJSON('/anvils/set_membership', {
                          host_uuid: node.node_uuid,
                          is_member: !(node.state === 'ready'),
                        })
                      }
                    />
                  </Box>
                </Box>
                {node.state !== 'ready' && (
                  <>
                    <Box display="flex" width="100%" className={classes.state}>
                      <Box flexGrow={1}>
                        <BodyText text={`State: ${node.state}`} />
                      </Box>
                      <Box>
                        <BodyText text={node.state_message} />
                      </Box>
                    </Box>
                    <Box display="flex" width="100%" className={classes.bar}>
                      <Box flexGrow={1}>
                        <ProgressBar progressPercentage={node.state_percent} />
                      </Box>
                    </Box>
                  </>
                )}
              </InnerPanel>
            );
          },
        )}
    </Box>
  );
};

export default AnvilNode;
