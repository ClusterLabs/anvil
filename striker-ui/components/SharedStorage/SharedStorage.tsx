import { useContext } from 'react';

import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';
import { BodyText, HeaderText } from '../Text';
import { Panel, InnerPanel, PanelHeader } from '../Panels';
import SharedStorageHost from './SharedStorageHost';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import { AnvilContext } from '../AnvilContext';
import Spinner from '../Spinner';
import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'SharedStorage';

const classes = {
  header: `${PREFIX}-header`,
  root: `${PREFIX}-root`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.header}`]: {
    paddingTop: '.1em',
    paddingRight: '.7em',
  },

  [`& .${classes.root}`]: {
    overflow: 'auto',
    height: '78vh',
    paddingLeft: '.3em',
    paddingRight: '.3em',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
    },
  },
}));

const SharedStorage = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const { data, isLoading } = PeriodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_shared_storage?anvil_uuid=${uuid}`,
  );
  return (
    <Panel>
      <StyledDiv>
        <HeaderText text="Shared Storage" />
        {!isLoading ? (
          <Box className={classes.root}>
            {data?.storage_groups &&
              data.storage_groups.map(
                (storageGroup: AnvilSharedStorageGroup): JSX.Element => (
                  <InnerPanel key={storageGroup.storage_group_uuid}>
                    <PanelHeader>
                      <Box
                        display="flex"
                        width="100%"
                        className={classes.header}
                      >
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
      </StyledDiv>
    </Panel>
  );
};

export default SharedStorage;
