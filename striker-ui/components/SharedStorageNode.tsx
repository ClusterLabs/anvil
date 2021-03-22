import { Grid, Switch } from '@material-ui/core';
import * as prettyBytes from 'pretty-bytes';

import InnerPanel from './InnerPanel';
import AllocationBar from './AllocationBar';
import { BodyText } from './Text';

const SharedStorageNode = ({
  node,
}: {
  node: AnvilSharedStorageNode;
}): JSX.Element => {
  return (
    <InnerPanel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={6}>
          <BodyText text={`Node: ${node.nodeInfo?.node_name}`} />
        </Grid>
        <Grid item xs={4}>
          <Switch checked={node.is_mounted} />
        </Grid>
        <Grid item xs={4}>
          <BodyText
            text={`Used: ${prettyBytes.default(node.total - node.free, {
              binary: true,
            })}`}
          />
        </Grid>
        <Grid item xs={4}>
          <BodyText
            text={`Free: ${prettyBytes.default(node.free, {
              binary: true,
            })}`}
          />
        </Grid>
        <Grid item xs={10}>
          <AllocationBar
            allocated={((node.total - node.free) / node.total) * 100}
          />
        </Grid>
        <Grid item xs={6}>
          <BodyText
            text={`Total Storage: ${prettyBytes.default(node.total, {
              binary: true,
            })}`}
          />
        </Grid>
      </Grid>
    </InnerPanel>
  );
};

export default SharedStorageNode;
