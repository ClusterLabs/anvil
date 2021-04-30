import { useContext } from 'react';

import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { BodyText, HeaderText } from './Text';
import Panel from './Panel';
import SharedStorageNode from './SharedStorageNode';
import InnerPanel from './InnerPanel';
import PanelHeader from './PanelHeader';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { AnvilContext } from './AnvilContext';

const useStyles = makeStyles((theme) => ({
  header: {
    paddingTop: '3px',
    paddingRight: '10px',
  },
  root: {
    overflow: 'auto',
    height: '80vh',
    paddingLeft: '5px',
    [theme.breakpoints.down('md')]: {
      height: '100%',
    },
  },
}));

const SharedStorage = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const classes = useStyles();
  const { uuid } = useContext(AnvilContext);
  const { data } = PeriodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_shared_storage?anvil_uuid=`,
    uuid,
  );
  return (
    <Panel>
      <HeaderText text="Shared Storage" />
      <Box className={classes.root}>
        {data?.file_systems &&
          data.file_systems.map(
            (fs: AnvilSharedStorageFileSystem): JSX.Element => (
              <InnerPanel key={fs.mount_point}>
                <PanelHeader>
                  <Box display="flex" width="100%" className={classes.header}>
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
                        node={{
                          ...node,
                          nodeInfo:
                            anvil[anvil.findIndex((a) => a.anvil_uuid === uuid)]
                              .nodes[index],
                        }}
                        key={fs.nodes[index].free}
                      />
                    ),
                  )}
              </InnerPanel>
            ),
          )}
      </Box>
    </Panel>
  );
};

export default SharedStorage;
