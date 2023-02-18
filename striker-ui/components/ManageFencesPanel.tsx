import { FC, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import AddFenceInputGroup from './AddFenceInputGroup';
import api from '../lib/api';
import ConfirmDialog from './ConfirmDialog';
import EditFenceInputGroup from './EditFenceInputGroup';
import FlexBox from './FlexBox';
import handleAPIError from '../lib/handleAPIError';
import List from './List';
import { Panel, PanelHeader } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from './Spinner';
import { BodyText, HeaderText, InlineMonoText } from './Text';
import useIsFirstRender from '../hooks/useIsFirstRender';
import useProtectedState from '../hooks/useProtectedState';

const ManageFencesPanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText: '',
      content: '',
      titleText: '',
    });
  const [fenceTemplate, setFenceTemplate] = useProtectedState<
    APIFenceTemplate | undefined
  >(undefined);
  const [isEditFences, setIsEditFences] = useState<boolean>(false);
  const [isLoadingFenceTemplate, setIsLoadingFenceTemplate] =
    useProtectedState<boolean>(true);

  const { data: fenceOverviews, isLoading: isFenceOverviewsLoading } =
    periodicFetch<APIFenceOverview>(`${API_BASE_URL}/fence`, {
      refreshInterval: 60000,
    });

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditFences}
        edit={isEditFences}
        header
        listItems={fenceOverviews}
        onAdd={() => {
          setConfirmDialogProps({
            actionProceedText: 'Add',
            content: <AddFenceInputGroup fenceTemplate={fenceTemplate} />,
            titleText: 'Add a fence device',
          });

          confirmDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditFences((previous) => !previous);
        }}
        onItemClick={({ fenceAgent: fenceId, fenceName, fenceParameters }) => {
          setConfirmDialogProps({
            actionProceedText: 'Update',
            content: (
              <EditFenceInputGroup
                fenceId={fenceId}
                fenceTemplate={fenceTemplate}
                previousFenceName={fenceName}
                previousFenceParameters={fenceParameters}
              />
            ),
            titleText: (
              <HeaderText>
                Update fence device{' '}
                <InlineMonoText variant="h4">{fenceName}</InlineMonoText>{' '}
                parameters
              </HeaderText>
            ),
          });

          confirmDialogRef.current.setOpen?.call(null, true);
        }}
        renderListItem={(
          fenceUUID,
          { fenceAgent, fenceName, fenceParameters },
        ) => (
          <FlexBox row>
            <BodyText>{fenceName}</BodyText>
            <BodyText>
              {Object.entries(fenceParameters).reduce<string>(
                (previous, [parameterId, parameterValue]) =>
                  `${previous} ${parameterId}="${parameterValue}"`,
                fenceAgent,
              )}
            </BodyText>
          </FlexBox>
        )}
      />
    ),
    [fenceOverviews, fenceTemplate, isEditFences],
  );
  const panelContent = useMemo(
    () =>
      isLoadingFenceTemplate || isFenceOverviewsLoading ? (
        <Spinner />
      ) : (
        listElement
      ),
    [isFenceOverviewsLoading, isLoadingFenceTemplate, listElement],
  );

  if (isFirstRender) {
    api
      .get<APIFenceTemplate>(`/fence/template`)
      .then(({ data }) => {
        setFenceTemplate(data);
      })
      .catch((error) => {
        handleAPIError(error);
      })
      .finally(() => {
        setIsLoadingFenceTemplate(false);
      });
  }

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage fence devices</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <ConfirmDialog
        dialogProps={{
          PaperProps: { sx: { minWidth: { xs: '90%', md: '50em' } } },
        }}
        formContent
        scrollContent
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ManageFencesPanel;
