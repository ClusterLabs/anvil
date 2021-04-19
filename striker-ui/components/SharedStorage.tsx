import { Box } from '@material-ui/core';

import { BodyText, HeaderText } from './Text';
import Panel from './Panel';
import SharedStorageNode from './SharedStorageNode';
import InnerPanel from './InnerPanel';
import PanelHeader from './PanelHeader';
import PeriodicFetch from '../lib/fetchers/periodicFetch';

const SharedStorage = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const { data } = PeriodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_shared_storage?anvil_uuid=`,
    anvil?.anvil_uuid,
  );
  return (
    <Panel>
      <HeaderText text="Shared Storage" />
      {data?.file_systems &&
        data.file_systems.map(
          (fs: AnvilSharedStorageFileSystem): JSX.Element => (
            <InnerPanel key={fs.mount_point}>
              <PanelHeader>
                <Box display="flex" width="100%">
                  <Box>
                    <BodyText text={fs.mount_point} />
                  </Box>
                </Box>
              </PanelHeader>
              {fs?.nodes &&
                fs.nodes.map(
                  (
                    node: AnvilSharedStorageNode,
                    index: number,
                  ): JSX.Element => (
                    <SharedStorageNode
                      node={{ ...node, nodeInfo: anvil.nodes[index] }}
                      key={anvil.nodes[index].node_uuid}
                    />
                  ),
                )}
            </InnerPanel>
          ),
        )}
    </Panel>
  );
};

export default SharedStorage;
