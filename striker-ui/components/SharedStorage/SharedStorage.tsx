import { Box as MuiBox, styled } from '@mui/material';
import { AxiosError } from 'axios';
import { useContext, useMemo, useRef, useState } from 'react';

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
import useConfirmDialog from '../../hooks/useConfirmDialog';
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
  const {
    anvil: anvilUuid,
    confirm,
    error,
    formDialogRef,
    loading,
    storages,
    target,
  } = props;

  const component = useMemo<React.ReactElement>(() => {
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

    const { confirmDialog } = confirm;

    const values = Object.values(storages.storageGroups);

    let formDialogHeader: React.ReactNode = 'Add storage group';

    if (target.value) {
      const { [target.value]: sg } = storages.storageGroups;

      if (sg) {
        formDialogHeader = `Update ${sg.name}`;
      }
    }

    return (
      <StyledDiv>
        <MuiBox className={classes.root}>
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
        </MuiBox>
        <DialogWithHeader
          header={formDialogHeader}
          onTransitionExited={() => {
            target.set();
          }}
          ref={formDialogRef}
          showClose
          wide
        >
          <StorageGroupForm
            anvil={anvilUuid}
            confirm={confirm}
            storages={storages}
            uuid={target.value}
          />
        </DialogWithHeader>
        {confirmDialog}
      </StyledDiv>
    );
  }, [anvilUuid, confirm, error, formDialogRef, loading, storages, target]);

  return component;
};

const SharedStorage: React.FC = () => {
  const { uuid: anvilUuid } = useContext(AnvilContext);

  const formDialogRef = useRef<DialogForwardedRefContent>(null);

  const confirm = useConfirmDialog();

  const [target, setTarget] = useState<string | undefined>();

  const {
    altData: storages,
    error,
    loading,
  } = useFetch<APIAnvilStorageList, APIAnvilSharedStorageOverview>(
    `/anvil/${anvilUuid}/storage`,
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
        anvil={anvilUuid}
        confirm={confirm}
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
