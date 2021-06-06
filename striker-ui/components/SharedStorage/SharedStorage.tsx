import { useContext } from 'react';

import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { BodyText, HeaderText } from '../Text';
import { Panel, InnerPanel, PanelHeader } from '../Panels';
import SharedStorageHost from './SharedStorageHost';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import { AnvilContext } from '../AnvilContext';
import Spinner from '../Spinner';

const useStyles = makeStyles((theme) => ({
  header: {
    paddingTop: '.1em',
    paddingRight: '.7em',
  },
  root: {
    overflow: 'auto',
    height: '78vh',
    paddingLeft: '.3em',
    [theme.breakpoints.down('md')]: {
      height: '100%',
    },
  },
}));

const SharedStorage = (): JSX.Element => {
  const classes = useStyles();
  const { uuid } = useContext(AnvilContext);
  const { data, isLoading } = PeriodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_shared_storage?anvil_uuid=${uuid}`,
  );
  return (
    <Panel>
      <HeaderText text="Shared Storage" />
      {!isLoading ? (
        <Box className={classes.root}>
          {data?.storage_groups &&
            data.storage_groups.map(
              (storageGroup: AnvilSharedStorageGroup): JSX.Element => (
                <InnerPanel key={storageGroup.storage_group_uuid}>
                  <PanelHeader>
                    <Box display="flex" width="100%" className={classes.header}>
                      <Box>
                        <BodyText text={storageGroup.storage_group_name} />
                      </Box>
                    </Box>
                  </PanelHeader>
                  <SharedStorageHost
                    group={storageGroup}
                    key={storageGroup.storage_group_uuid}
                  />
                </InnerPanel>
              ),
            )}
        </Box>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default SharedStorage;
