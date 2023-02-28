import { Box } from '@mui/material';
import {
  FC,
  FormEventHandler,
  ReactElement,
  useMemo,
  useRef,
  useState,
} from 'react';

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
import {
  BodyText,
  HeaderText,
  InlineMonoText,
  MonoText,
  SmallText,
} from './Text';
import useIsFirstRender from '../hooks/useIsFirstRender';
import useProtectedState from '../hooks/useProtectedState';
import SensitiveText from './Text/SensitiveText';

type FormFenceParameterData = {
  fenceAgent: string;
  fenceName: string;
  parameterInputs: {
    [parameterInputId: string]: {
      isParameterSensitive: boolean;
      parameterId: string;
      parameterType: string;
      parameterValue: string;
    };
  };
};

const fenceParameterBooleanToString = (value: boolean) => (value ? '1' : '0');

const getFormFenceParameters = (
  fenceTemplate: APIFenceTemplate,
  ...[{ target }]: Parameters<FormEventHandler<HTMLDivElement>>
) => {
  const { elements } = target as HTMLFormElement;

  return Object.values(elements).reduce<FormFenceParameterData>(
    (previous, formElement) => {
      const { id: inputId } = formElement;
      const reExtract = new RegExp(`^(fence[^-]+)${ID_SEPARATOR}([^\\s]+)$`);
      const matched = inputId.match(reExtract);

      if (matched) {
        const [, fenceId, parameterId] = matched;

        previous.fenceAgent = fenceId;

        const inputElement = formElement as HTMLInputElement;
        const {
          checked,
          dataset: { sensitive: rawSensitive },
          value,
        } = inputElement;

        if (parameterId === 'name') {
          previous.fenceName = value;
        }

        const {
          [fenceId]: {
            parameters: {
              [parameterId]: { content_type: parameterType = 'string' } = {},
            },
          },
        } = fenceTemplate;

        previous.parameterInputs[inputId] = {
          isParameterSensitive: rawSensitive === 'true',
          parameterId,
          parameterType,
          parameterValue:
            parameterType === 'boolean'
              ? fenceParameterBooleanToString(checked)
              : value,
        };
      }

      return previous;
    },
    { fenceAgent: '', fenceName: '', parameterInputs: {} },
  );
};

const buildConfirmFenceParameters = (
  parameterInputs: FormFenceParameterData['parameterInputs'],
) => (
  <List
    listItems={parameterInputs}
    listItemProps={{ sx: { padding: 0 } }}
    renderListItem={(
      parameterInputId,
      { isParameterSensitive, parameterId, parameterValue },
    ) => {
      let textElement: ReactElement;

      if (parameterValue) {
        textElement = isParameterSensitive ? (
          <SensitiveText monospaced>{parameterValue}</SensitiveText>
        ) : (
          <Box sx={{ maxWidth: '100%', overflowX: 'scroll' }}>
            <MonoText lineHeight={2.8} whiteSpace="nowrap">
              {parameterValue}
            </MonoText>
          </Box>
        );
      } else {
        textElement = <SmallText>none</SmallText>;
      }

      return (
        <FlexBox
          fullWidth
          growFirst
          height="2.8em"
          key={`confirm-${parameterInputId}`}
          maxWidth="100%"
          row
        >
          <BodyText>{parameterId}</BodyText>
          {textElement}
        </FlexBox>
      );
    }}
  />
);

const ManageFencesPanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const formDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText: '',
      content: '',
      titleText: '',
    });
  const [formDialogProps, setFormDialogProps] = useState<ConfirmDialogProps>({
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
          setFormDialogProps({
            actionProceedText: 'Add',
            content: <AddFenceInputGroup fenceTemplate={fenceTemplate} />,
            onSubmitAppend: (event) => {
              if (!fenceTemplate) {
                return;
              }

              const addData = getFormFenceParameters(fenceTemplate, event);

              setConfirmDialogProps({
                actionProceedText: 'Add',
                content: buildConfirmFenceParameters(addData.parameterInputs),
                titleText: (
                  <HeaderText>
                    Add a{' '}
                    <InlineMonoText fontSize="inherit">
                      {addData.fenceAgent}
                    </InlineMonoText>{' '}
                    fence device with the following parameters?
                  </HeaderText>
                ),
              });

              confirmDialogRef.current.setOpen?.call(null, true);
            },
            titleText: 'Add a fence device',
          });

          formDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditFences((previous) => !previous);
        }}
        onItemClick={({ fenceAgent: fenceId, fenceName, fenceParameters }) => {
          setFormDialogProps({
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

              const editData = getFormFenceParameters(fenceTemplate, event);

              setConfirmDialogProps({
                actionProceedText: 'Update',
                content: buildConfirmFenceParameters(editData.parameterInputs),
                titleText: (
                  <HeaderText>
                    Update{' '}
                    <InlineMonoText fontSize="inherit">
                      {editData.fenceName}
                    </InlineMonoText>{' '}
                    fence device with the following parameters?
                  </HeaderText>
                ),
              });

              confirmDialogRef.current.setOpen?.call(null, true);
            },
            titleText: (
              <HeaderText>
                Update fence device{' '}
                <InlineMonoText fontSize="inherit">{fenceName}</InlineMonoText>{' '}
                parameters
              </HeaderText>
            ),
          });

          formDialogRef.current.setOpen?.call(null, true);
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
        scrollBoxProps={{
          padding: '.3em .5em',
        }}
        scrollContent
        {...formDialogProps}
        ref={formDialogRef}
      />
      <ConfirmDialog
        scrollBoxProps={{ paddingRight: '1em' }}
        scrollContent
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ManageFencesPanel;
