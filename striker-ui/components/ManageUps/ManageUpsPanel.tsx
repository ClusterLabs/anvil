import { FC, useMemo, useRef, useState } from 'react';

import AddUpsInputGroup from './AddUpsInputGroup';
import api from '../../lib/api';
import ConfirmDialog from '../ConfirmDialog';
import FormDialog from '../FormDialog';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useIsFirstRender from '../../hooks/useIsFirstRender';
import useProtectedState from '../../hooks/useProtectedState';

const ManageUpsPanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const formDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [confirmDialogProps] = useConfirmDialogProps();
  const [formDialogProps, setFormDialogProps] = useConfirmDialogProps();
  const [isEditUpses, setIsEditUpses] = useState<boolean>(false);
  const [isLoadingUpsTemplate, setIsLoadingUpsTemplate] =
    useProtectedState<boolean>(true);
  const [upsTemplate, setUpsTemplate] = useProtectedState<
    APIUpsTemplate | undefined
  >(undefined);

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditUpses}
        edit={isEditUpses}
        header
        listEmpty="No Ups(es) registered."
        onAdd={() => {
          setFormDialogProps({
            actionProceedText: 'Add',
            content: <AddUpsInputGroup upsTemplate={upsTemplate} />,
            titleText: 'Add a UPS',
          });

          formDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditUpses((previous) => !previous);
        }}
      />
    ),
    [isEditUpses, setFormDialogProps, upsTemplate],
  );
  const panelContent = useMemo(
    () => (isLoadingUpsTemplate ? <Spinner /> : listElement),
    [isLoadingUpsTemplate, listElement],
  );

  if (isFirstRender) {
    api
      .get<APIUpsTemplate>('/ups/template')
      .then(({ data }) => {
        setUpsTemplate(data);
      })
      .catch((error) => {
        handleAPIError(error);
      })
      .finally(() => {
        setIsLoadingUpsTemplate(false);
      });
  }

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage Upses</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <FormDialog {...formDialogProps} ref={formDialogRef} />
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ManageUpsPanel;
