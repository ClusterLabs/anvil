import {
  FC,
  FormEventHandler,
  ReactNode,
  useCallback,
  useMemo,
  useRef,
  useState,
} from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { REP_LABEL_PASSW } from '../../lib/consts/REG_EXP_PATTERNS';

import AddFenceInputGroup, { INPUT_ID_FENCE_AGENT } from './AddFenceInputGroup';
import api from '../../lib/api';
import { INPUT_ID_SEPARATOR } from './CommonFenceInputGroup';
import ConfirmDialog from '../ConfirmDialog';
import EditFenceInputGroup from './EditFenceInputGroup';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { BodyText, HeaderText, InlineMonoText, SensitiveText } from '../Text';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFormUtils from '../../hooks/useFormUtils';
import useIsFirstRender from '../../hooks/useIsFirstRender';

type FenceFormData = {
  agent: string;
  name: string;
  parameters: { [parameterId: string]: string };
};

const assertFormInputId = (element: Element) => {
  const { id } = element;

  const re = new RegExp(`^(fence[^-]+)${INPUT_ID_SEPARATOR}([^\\s]+)$`);
  const matched = id.match(re);

  if (!matched) throw Error('Not target input element');

  return matched;
};

const assertFormInputName = (
  paramId: string,
  parent: FenceFormData,
  value: string,
) => {
  if (paramId === 'name') {
    parent.name = value;

    throw Error('Not child parameter');
  }
};

const assertFormParamSpec = (
  spec: APIFenceTemplate[string]['parameters'][string],
) => {
  if (!spec) throw Error('Not parameter specification');
};

const assertFormParamValue = (value: string, paramDefault?: string) => {
  if ([paramDefault, '', null, undefined].some((bad) => value === bad))
    throw Error('Skippable parameter value');
};

const getFormData = (
  fenceTemplate: APIFenceTemplate,
  ...[{ target }]: Parameters<FormEventHandler<HTMLDivElement>>
) => {
  const { elements } = target as HTMLFormElement;

  return Object.values(elements).reduce<FenceFormData>(
    (previous, element) => {
      try {
        const matched = assertFormInputId(element);

        const [, fenceId, paramId] = matched;

        previous.agent = fenceId;

        const inputElement = element as HTMLInputElement;
        const { checked, value } = inputElement;

        assertFormInputName(paramId, previous, value);

        const {
          [fenceId]: {
            parameters: { [paramId]: paramSpec },
          },
        } = fenceTemplate;

        assertFormParamSpec(paramSpec);

        const { content_type: paramType, default: paramDefault } = paramSpec;

        let paramValue = value;

        if (paramType === 'boolean') {
          paramValue = checked ? '1' : '';
        }

        assertFormParamValue(paramValue, paramDefault);

        previous.parameters[paramId] = paramValue;
      } catch (error) {
        return previous;
      }

      return previous;
    },
    { agent: '', name: '', parameters: {} },
  );
};

const ManageFencePanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const formDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();
  const [formDialogProps, setFormDialogProps] = useConfirmDialogProps();

  const [fenceOverviews, setFenceOverviews] = useState<
    APIFenceOverview | undefined
  >();
  const [fenceTemplate, setFenceTemplate] = useState<
    APIFenceTemplate | undefined
  >();
  const [isEditFences, setIsEditFences] = useState<boolean>(false);
  const [isLoadingFenceTemplate, setIsLoadingFenceTemplate] =
    useState<boolean>(true);

  const { isLoading: isFenceOverviewsLoading } =
    periodicFetch<APIFenceOverview>(`${API_BASE_URL}/fence`, {
      onSuccess: (data) => setFenceOverviews(data),
      refreshInterval: 60000,
    });

  const getFenceOverviews = useCallback(() => {
    api.get('/fence').then(({ data }) => {
      setFenceOverviews(data);
    });
  }, [setFenceOverviews]);

  const formUtils = useFormUtils([INPUT_ID_FENCE_AGENT], messageGroupRef);
  const { isFormInvalid, isFormSubmitting, submitForm } = formUtils;

  const {
    buildDeleteDialogProps,
    checks,
    getCheck,
    hasChecks,
    resetChecks,
    setCheck,
  } = useChecklist({ list: fenceOverviews });

  const getFormSummaryEntryLabel = useCallback<GetFormEntryLabelFunction>(
    ({ cap, depth, key }) => (depth === 0 ? cap(key) : key),
    [],
  );

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditFences}
        disableDelete={!hasChecks}
        edit={isEditFences}
        header
        listItems={fenceOverviews}
        onAdd={() => {
          setFormDialogProps({
            actionProceedText: 'Add',
            content: (
              <AddFenceInputGroup
                fenceTemplate={fenceTemplate}
                formUtils={formUtils}
              />
            ),
            onSubmitAppend: (event) => {
              if (!fenceTemplate) {
                return;
              }

              const addData = getFormData(fenceTemplate, event);
              const { agent, name } = addData;

              setConfirmDialogProps({
                actionProceedText: 'Add',
                content: (
                  <FormSummary
                    entries={addData}
                    hasPassword
                    getEntryLabel={getFormSummaryEntryLabel}
                  />
                ),
                onProceedAppend: () => {
                  submitForm({
                    body: addData,
                    getErrorMsg: (parentMsg) => (
                      <>Failed to add fence device. {parentMsg}</>
                    ),
                    method: 'post',
                    onSuccess: () => getFenceOverviews(),
                    successMsg: `Added fence device ${name}`,
                    url: '/fence',
                  });
                },
                titleText: (
                  <HeaderText>
                    Add a{' '}
                    <InlineMonoText fontSize="inherit">{agent}</InlineMonoText>{' '}
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
        onDelete={() => {
          setConfirmDialogProps(
            buildDeleteDialogProps({
              getConfirmDialogTitle: (count) =>
                `Delete ${count} fence device(s)?`,
              onProceedAppend: () => {
                submitForm({
                  body: { uuids: checks },
                  getErrorMsg: (parentMsg) => (
                    <>Failed to delete fence device(s). {parentMsg}</>
                  ),
                  method: 'delete',
                  onSuccess: () => {
                    getFenceOverviews();
                    resetChecks();
                  },
                  url: '/fence',
                });
              },
              renderEntry: ({ key }) => (
                <BodyText>{fenceOverviews?.[key].fenceName}</BodyText>
              ),
            }),
          );

          confirmDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditFences((previous) => !previous);
        }}
        onItemCheckboxChange={(key, event, checked) => {
          setCheck(key, checked);
        }}
        onItemClick={({
          fenceAgent: fenceId,
          fenceName,
          fenceParameters,
          fenceUUID,
        }) => {
          setFormDialogProps({
            actionProceedText: 'Update',
            content: (
              <EditFenceInputGroup
                fenceId={fenceId}
                fenceTemplate={fenceTemplate}
                formUtils={formUtils}
                previousFenceName={fenceName}
                previousFenceParameters={fenceParameters}
              />
            ),
            onSubmitAppend: (event) => {
              if (!fenceTemplate) {
                return;
              }

              const editData = getFormData(fenceTemplate, event);

              setConfirmDialogProps({
                actionProceedText: 'Update',
                content: (
                  <FormSummary
                    entries={editData}
                    hasPassword
                    getEntryLabel={getFormSummaryEntryLabel}
                  />
                ),
                onProceedAppend: () => {
                  submitForm({
                    body: editData,
                    getErrorMsg: (parentMsg) => (
                      <>Failed to update fence device. {parentMsg}</>
                    ),
                    method: 'put',
                    onSuccess: () => getFenceOverviews(),
                    successMsg: `Updated fence device ${fenceName}`,
                    url: `/fence/${fenceUUID}`,
                  });
                },
                titleText: (
                  <HeaderText>
                    Update{' '}
                    <InlineMonoText fontSize="inherit">
                      {fenceName}
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
        renderListItemCheckboxState={(key) => getCheck(key)}
        renderListItem={(
          fenceUUID,
          { fenceAgent, fenceName, fenceParameters },
        ) => (
          <FlexBox row>
            <BodyText>{fenceName}</BodyText>
            <BodyText>
              {Object.entries(fenceParameters).reduce<ReactNode>(
                (previous, [parameterId, parameterValue]) => {
                  let current: ReactNode = <>{parameterId}=&quot;</>;

                  current = REP_LABEL_PASSW.test(parameterId) ? (
                    <>
                      {current}
                      <SensitiveText wrapper="mono">
                        {parameterValue}
                      </SensitiveText>
                    </>
                  ) : (
                    <>
                      {current}
                      {parameterValue}
                    </>
                  );

                  return (
                    <>
                      {previous} {current}&quot;
                    </>
                  );
                },
                fenceAgent,
              )}
            </BodyText>
          </FlexBox>
        )}
      />
    ),
    [
      buildDeleteDialogProps,
      checks,
      fenceOverviews,
      fenceTemplate,
      formUtils,
      getCheck,
      getFenceOverviews,
      getFormSummaryEntryLabel,
      hasChecks,
      isEditFences,
      resetChecks,
      setCheck,
      setConfirmDialogProps,
      setFormDialogProps,
      submitForm,
    ],
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

  const messageArea = useMemo(
    () => (
      <MessageGroup
        count={1}
        defaultMessageType="warning"
        ref={messageGroupRef}
      />
    ),
    [],
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
      <FormDialog
        dialogProps={{
          PaperProps: { sx: { minWidth: { xs: '90%', md: '50em' } } },
        }}
        scrollBoxProps={{
          padding: '.3em .5em',
        }}
        {...formDialogProps}
        disableProceed={isFormInvalid}
        loadingAction={isFormSubmitting}
        preActionArea={messageArea}
        ref={formDialogRef}
        scrollContent
        showClose
      />
      <ConfirmDialog
        closeOnProceed
        scrollBoxProps={{ paddingRight: '1em' }}
        {...confirmDialogProps}
        ref={confirmDialogRef}
        scrollContent
      />
    </>
  );
};

export default ManageFencePanel;
