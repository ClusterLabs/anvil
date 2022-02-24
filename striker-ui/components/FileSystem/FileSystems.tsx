import { useContext } from 'react';

import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';
import { BodyText, HeaderText } from '../Text';
import { Panel, InnerPanel, InnerPanelHeader } from '../Panels';
import SharedStorageHost from './FileSystemsHost';
import periodicFetch from '../../lib/fetchers/periodicFetch';
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
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      height: '100%',
    },
  },
}));

const SharedStorage = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const { data, isLoading } = periodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_shared_storage?anvil_uuid=${uuid}`,
  );
  return (
    <Panel>
      <StyledDiv>
        <HeaderText text="Shared Storage" />
        {!isLoading ? (
          <Box className={classes.root}>
            {data?.file_systems &&
              data.file_systems.map(
                (fs: AnvilFileSystem): JSX.Element => (
                  <InnerPanel key={fs.mount_point}>
                    <InnerPanelHeader>
                      <Box
                        display="flex"
                        width="100%"
                        className={classes.header}
                      >
                        <Box>
                          <BodyText text={fs.mount_point} />
                        </Box>
                      </Box>
                    </InnerPanelHeader>
                    {fs?.hosts &&
                      fs.hosts.map(
                        (
                          host: AnvilFileSystemHost,
                          index: number,
                        ): JSX.Element => (
                          <SharedStorageHost
                            host={{
                              ...host,
                              ...anvil[
                                anvil.findIndex((a) => a.anvil_uuid === uuid)
                              ].hosts[index],
                            }}
                            key={fs.hosts[index].free}
                          />
                        ),
                      )}
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
