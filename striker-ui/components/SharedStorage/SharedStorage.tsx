import { Box, styled } from '@mui/material';
import { AxiosError } from 'axios';
import { useContext, useRef, useState } from 'react';

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
  const { error, formDialogRef, loading, storages, target } = props;

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

  let formDialogHeader: React.ReactNode = 'Add storage group';

  if (target.value) {
    const { [target.value]: sg } = storages.storageGroups;

    formDialogHeader = `Update ${sg.name.toLocaleLowerCase()}`;
  }

  return (
    <StyledDiv>
      <Box className={classes.root}>
        {values.map(
          ({ uuid }): React.ReactNode => (
            <StorageGroup
              formDialogRef={formDialogRef}
              key={uuid}
              storages={storages}
              target={target}
              uuid={uuid}
            />
          ),
        )}
      </Box>
      <DialogWithHeader
        header={formDialogHeader}
        ref={formDialogRef}
        showClose
        wide
      >
        <StorageGroupForm storages={storages} uuid={target.value} />
      </DialogWithHeader>
    </StyledDiv>
  );
};

const SharedStorage = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const formDialogRef = useRef<DialogForwardedRefContent>(null);

  const [target, setTarget] = useState<string | undefined>();

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
            setTarget(undefined);

            formDialogRef.current?.setOpen(true);
          }}
        />
      </PanelHeader>
      <SharedStorageContent
        error={error}
        formDialogRef={formDialogRef}
        loading={loading}
        storages={storages}
        target={{
          set: setTarget,
          value: target,
        }}
      />
    </Panel>
  );
};

export default SharedStorage;
