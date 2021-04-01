import { Grid, Switch } from '@material-ui/core';

import InnerPanel from './InnerPanel';
import ProgressBar from './ProgressBar';
import { BodyText } from './Text';
import PanelHeader from './PanelHeader';

const AnvilNode = ({
  node,
}: {
  node: Array<AnvilStatusNode & AnvilListItemNode>;
}): JSX.Element => {
  return (
    <>
      {node &&
        node.map(
          (n): JSX.Element => {
            return (
              <InnerPanel key={n.node_uuid}>
                <PanelHeader>
                  <Grid container alignItems="center" justify="space-around">
                    <Grid item xs={7}>
                      <BodyText text={`Node: ${n.node_name}`} />
                    </Grid>
                    <Grid item xs={3}>
                      <Switch checked />
                    </Grid>
                  </Grid>
                </PanelHeader>
                <Grid container alignItems="center" justify="space-around">
                  <Grid item xs={5}>
                    <BodyText text={`State: ${n.state}`} />
                  </Grid>
                  <Grid item xs={4}>
                    <BodyText text={n.state_message} />
                  </Grid>
                  <Grid item xs={10}>
                    <ProgressBar progressPercentage={n.state_percent} />
                  </Grid>
                </Grid>
              </InnerPanel>
            );
          },
        )}
    </>
  );
};

export default AnvilNode;
