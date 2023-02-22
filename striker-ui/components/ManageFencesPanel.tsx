import { FC, FormEventHandler, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import AddFenceInputGroup from './AddFenceInputGroup';
import api from '../lib/api';
import { ID_SEPARATOR } from './CommonFenceInputGroup';
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

const fenceParameterBooleanToString = (value: boolean) => (value ? '1' : '0');

const getFormFenceParameters = (
  fenceTemplate: APIFenceTemplate,
  ...[{ target }]: Parameters<FormEventHandler<HTMLDivElement>>
) => {
  const { elements } = target as HTMLFormElement;

  return Object.values(elements).reduce<{
    fenceAgent: string;
    parameters: {
      [parameterId: string]: { type: string; value: string };
    };
  }>(
    (previous, formElement) => {
      const { id: inputId } = formElement;
      const reExtract = new RegExp(`^(fence[^-]+)${ID_SEPARATOR}([^\\s]+)$`);
      const matched = inputId.match(reExtract);

      if (matched) {
        const [, fenceId, parameterId] = matched;

        previous.fenceAgent = fenceId;

        const inputElement = formElement as HTMLInputElement;
        const { checked, value } = inputElement;
        const {
          [fenceId]: {
            parameters: {
              [parameterId]: { content_type: parameterType = 'string' } = {},
            },
          },
        } = fenceTemplate;

        previous.parameters[parameterId] = {
          type: parameterType,
          value:
            parameterType === 'boolean'
              ? fenceParameterBooleanToString(checked)
              : value,
        };
      }

      return previous;
    },
    { fenceAgent: '', parameters: {} },
  );
};

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
            onSubmitAppend: (event) => {
              if (!fenceTemplate) {
                return;
              }

              getFormFenceParameters(fenceTemplate, event);
            },
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
            onSubmitAppend: (event) => {
              if (!fenceTemplate) {
                return;
              }

              getFormFenceParameters(fenceTemplate, event);
            },
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
