import { Box, styled } from '@mui/material';
import { useContext } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

import { AnvilContext } from '../AnvilContext';
import { Panel, InnerPanel, InnerPanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import SharedStorageHost from './SharedStorageHost';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';

const PREFIX = 'SharedStorage';

const classes = {
  root: `${PREFIX}-root`,
};

const StyledDiv = styled('div')(({ theme }) => ({
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

  const { data, isLoading } = periodicFetch<AnvilSharedStorage>(
    `${API_BASE_URL}/anvil/${uuid}/store`,
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
                    <InnerPanelHeader>
                      <BodyText text={storageGroup.storage_group_name} />
                    </InnerPanelHeader>
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
