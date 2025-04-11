import { Box, styled } from '@mui/material';
import { AxiosError } from 'axios';
import { useContext } from 'react';

import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

import { AnvilContext } from '../AnvilContext';
import { toAnvilSharedStorageOverview } from '../../lib/api_converters';
import handleAPIError from '../../lib/handleAPIError';
import MessageBox from '../MessageBox';
import { Panel, InnerPanel, InnerPanelHeader, PanelHeader } from '../Panels';
import StorageGroup from './StorageGroup';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import useFetch from '../../hooks/useFetch';

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

const SharedStorageContent: React.FC<
  SharedStorageContentProps<AxiosError<unknown, APIAnvilStorageList>>
> = (props) => {
  const { error, loading, storages: storage } = props;

  if (loading) {
    return <Spinner />;
  }

  if (!storage) {
    let emsg: Message;

    if (error) {
      emsg = handleAPIError(error);

      emsg.children = <>Failed to get storage information. {emsg.children}</>;
    } else {
      emsg = {
        children: <>Cannot find storage information.</>,
        type: 'warning',
      };
    }

    return <MessageBox {...emsg} />;
  }

  const values = Object.values(storage.storageGroups);

  return (
    <StyledDiv>
      <Box className={classes.root}>
        {values.map(
          (storageGroup): JSX.Element => (
            <InnerPanel key={storageGroup.uuid}>
              <InnerPanelHeader>
                <BodyText text={storageGroup.name} />
              </InnerPanelHeader>
              <StorageGroup storageGroup={storageGroup} />
            </InnerPanel>
          ),
        )}
      </Box>
    </StyledDiv>
  );
};

const SharedStorage = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const {
    altData: storages,
    error,
    loading,
  } = useFetch<APIAnvilStorageList, APIAnvilSharedStorageOverview>(
    `/anvil/${uuid}/storage`,
    {
      mod: toAnvilSharedStorageOverview,
      periodic: true,
    },
  );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText>Shared Storage</HeaderText>
      </PanelHeader>
      <SharedStorageContent
        error={error}
        loading={loading}
        storages={storages}
      />
    </Panel>
  );
};

export default SharedStorage;
