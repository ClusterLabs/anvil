import { Grid } from '@material-ui/core';
import Panel from './Panel';
import SharedStorageNode from './SharedStorageNode';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';

const SharedStorage = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const { data } = PeriodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_shared_storage?anvil_uuid=`,
    anvil.anvil_uuid,
  );

  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Shared Storage" />
        </Grid>
        <Grid item xs={12}>
          <BodyText text="Mount /mnt/shared" />
        </Grid>
        <Grid item xs={12}>
          {data &&
            data.file_systems[0]?.nodes.map(
              (node: AnvilSharedStorageNode, index: number): JSX.Element => (
                <SharedStorageNode
                  node={{ ...node, nodeInfo: anvil.nodes[index] }}
                  key={anvil.nodes[index].node_uuid}
                />
              ),
            )}
        </Grid>
      </Grid>
    </Panel>
  );
};

export default SharedStorage;
