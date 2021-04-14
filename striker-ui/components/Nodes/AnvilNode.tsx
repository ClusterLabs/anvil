import { Box, Switch } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import InnerPanel from '../InnerPanel';
import { ProgressBar } from '../Bars';
import { BodyText } from '../Text';
import PanelHeader from '../PanelHeader';

const useStyles = makeStyles(() => ({
  state: {
    paddingLeft: '10px',
    paddingRight: '10px',
    paddingTop: '20px',
  },
  bar: {
    paddingLeft: '10px',
    paddingRight: '10px',
  },
}));

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
                    <Box>
                      <Switch checked />
                    </Box>
                  </Box>
                </PanelHeader>
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
              </InnerPanel>
            );
          },
        )}
    </>
  );
};

export default AnvilNode;
