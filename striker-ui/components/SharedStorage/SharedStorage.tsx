import { Box, styled } from '@mui/material';
import { AxiosError } from 'axios';
import { useContext, useRef } from 'react';

import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

import { AnvilContext } from '../AnvilContext';
import { toAnvilSharedStorageOverview } from '../../lib/api_converters';
import { DialogWithHeader } from '../Dialog';
import handleAPIError from '../../lib/handleAPIError';
import IconButton from '../IconButton';
import MessageBox from '../MessageBox';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import StorageGroup from './StorageGroup';
import StorageGroupForm from './StorageGroupForm';
import { HeaderText } from '../Text';
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
  const { error, formDialogRef, loading, storages } = props;

  if (loading) {
    return <Spinner />;
  }

  if (!storages) {
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

  const values = Object.values(storages.storageGroups);

  return (
    <StyledDiv>
      <Box className={classes.root}>
        {values.map(
          (storageGroup): JSX.Element => (
            <StorageGroup
              key={storageGroup.uuid}
              storages={storages}
              uuid={storageGroup.uuid}
            />
          ),
        )}
      </Box>
      <DialogWithHeader
        header="Manage storage group"
        ref={formDialogRef}
        showClose
      >
        <StorageGroupForm storages={storages} />
      </DialogWithHeader>
    </StyledDiv>
  );
};

const SharedStorage = (): JSX.Element => {
  const formDialogRef = useRef<DialogForwardedRefContent>(null);

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
        <IconButton
          mapPreset="add"
          onClick={() => {
            formDialogRef.current?.setOpen(true);
          }}
        />
      </PanelHeader>
      <SharedStorageContent
        error={error}
        formDialogRef={formDialogRef}
        loading={loading}
        storages={storages}
      />
    </Panel>
  );
};

export default SharedStorage;
