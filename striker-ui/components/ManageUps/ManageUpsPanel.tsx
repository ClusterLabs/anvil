import { useCallback, useMemo, useRef, useState } from 'react';

import AddUpsInputGroup, { INPUT_ID_UPS_TYPE } from './AddUpsInputGroup';
import api from '../../lib/api';
import { INPUT_ID_UPS_IP, INPUT_ID_UPS_NAME } from './CommonUpsInputGroup';
import ConfirmDialog from '../ConfirmDialog';
import EditUpsInputGroup, { INPUT_ID_UPS_UUID } from './EditUpsInputGroup';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText, InlineMonoText, MonoText } from '../Text';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFetch from '../../hooks/useFetch';
import useFormUtils from '../../hooks/useFormUtils';
import useIsFirstRender from '../../hooks/useIsFirstRender';

type UpsFormData = {
  agent: string;
  brand: string;
  ipAddress: string;
  name: string;
  typeId: string;
  uuid: string;
};

const getFormData = (
  upsTemplate: APIUpsTemplate,
  ...[{ target }]: Parameters<React.FormEventHandler<HTMLDivElement>>
): UpsFormData => {
  const { elements } = target as HTMLFormElement;

  const { value: name } = elements.namedItem(
    INPUT_ID_UPS_NAME,
  ) as HTMLInputElement;
  const { value: ipAddress } = elements.namedItem(
    INPUT_ID_UPS_IP,
  ) as HTMLInputElement;

  const inputUpsTypeId = elements.namedItem(INPUT_ID_UPS_TYPE);

  let agent = '';
  let brand = '';
  let typeId = '';

  if (inputUpsTypeId) {
    ({ value: typeId } = inputUpsTypeId as HTMLInputElement);
    ({ agent, brand } = upsTemplate[typeId]);
  }

  const inputUpsUUID = elements.namedItem(INPUT_ID_UPS_UUID);

  let uuid = '';

  if (inputUpsUUID) {
    ({ value: uuid } = inputUpsUUID as HTMLInputElement);
  }

  return {
    agent,
    brand,
    ipAddress,
    name,
    typeId,
    uuid,
  };
};

const buildConfirmUpsFormData = ({
  brand,
  ipAddress,
  name,
  uuid,
}: UpsFormData) => {
  const listItems: Record<string, { label: string; value: string }> = {
    'ups-brand': { label: 'Brand', value: brand },
    'ups-name': { label: 'Host name', value: name },
    'ups-ip-address': { label: 'IP address', value: ipAddress },
  };

  return (
    <List
      listItems={listItems}
      listItemProps={{ sx: { padding: 0 } }}
      renderListItem={(part, { label, value }) => (
        <FlexBox fullWidth growFirst key={`confirm-ups-${uuid}-${part}`} row>
          <BodyText>{label}</BodyText>
          <MonoText>{value}</MonoText>
        </FlexBox>
      )}
    />
  );
};

const ManageUpsPanel: React.FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const formDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();
  const [formDialogProps, setFormDialogProps] = useConfirmDialogProps();

  const [isEditUpses, setIsEditUpses] = useState<boolean>(false);
  const [isLoadingUpsTemplate, setIsLoadingUpsTemplate] =
    useState<boolean>(true);
  const [upsTemplate, setUpsTemplate] = useState<APIUpsTemplate | undefined>();

  const { data: upsOverviews, loading: isUpsOverviewLoading } =
    useFetch<APIUpsOverview>(`/ups`, {
      refreshInterval: 60000,
    });

  const formUtils = useFormUtils(
    [INPUT_ID_UPS_IP, INPUT_ID_UPS_NAME, INPUT_ID_UPS_TYPE],
    messageGroupRef,
  );
  const { isFormInvalid, isFormSubmitting, submitForm } = formUtils;

  const { buildDeleteDialogProps, checks, getCheck, hasChecks, setCheck } =
    useChecklist({
      list: upsOverviews,
    });

  const buildEditUpsFormDialogProps = useCallback<
    (args: APIUpsOverview[string]) => ConfirmDialogProps
  >(
    ({ upsAgent, upsIPAddress, upsName, upsUUID }) => {
      // Determine the type of existing UPS based on its scan agent.
      // TODO: should identity an existing UPS's type in the DB.
      const upsTypeId: string =
        Object.entries(upsTemplate ?? {}).find(
          ([, { agent }]) => upsAgent === agent,
        )?.[0] ?? '';

      return {
        actionProceedText: 'Update',
        content: (
          <EditUpsInputGroup
            formUtils={formUtils}
            previous={{
              upsIPAddress,
              upsName,
              upsTypeId,
            }}
            upsTemplate={upsTemplate}
            upsUUID={upsUUID}
          />
        ),
        onSubmitAppend: (event) => {
          if (!upsTemplate) {
            return;
          }

          const editData = getFormData(upsTemplate, event);
          const { name: newUpsName } = editData;

          setConfirmDialogProps({
            actionProceedText: 'Update',
            content: buildConfirmUpsFormData(editData),
            onProceedAppend: () => {
              submitForm({
                body: editData,
                getErrorMsg: (parentMsg) => (
                  <>Failed to update UPS. {parentMsg}</>
                ),
                method: 'put',
                successMsg: `Successfully updated UPS ${upsName}`,
                url: `/ups/${upsUUID}`,
              });
            },
            titleText: (
              <HeaderText>
                Update{' '}
                <InlineMonoText fontSize="inherit">{newUpsName}</InlineMonoText>{' '}
                with the following data?
              </HeaderText>
            ),
          });

          confirmDialogRef.current.setOpen?.call(null, true);
        },
        titleText: (
          <HeaderText>
            Update UPS{' '}
            <InlineMonoText fontSize="inherit">{upsName}</InlineMonoText>
          </HeaderText>
        ),
      };
    },
    [formUtils, setConfirmDialogProps, submitForm, upsTemplate],
  );

  const addUpsFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Add',
      content: (
        <AddUpsInputGroup formUtils={formUtils} upsTemplate={upsTemplate} />
      ),
      onSubmitAppend: (event) => {
        if (!upsTemplate) {
          return;
        }

        const addData = getFormData(upsTemplate, event);
        const { brand: upsBrand, name: upsName } = addData;

        setConfirmDialogProps({
          actionProceedText: 'Add',
          content: buildConfirmUpsFormData(addData),
          onProceedAppend: () => {
            submitForm({
              body: addData,
              getErrorMsg: (parentMsg) => <>Failed to add UPS. {parentMsg}</>,
              method: 'post',
              successMsg: `Successfully added UPS ${upsName}`,
              url: '/ups',
            });
          },
          titleText: (
            <HeaderText>
              Add a{' '}
              <InlineMonoText fontSize="inherit">{upsBrand}</InlineMonoText> UPS
              with the following data?
            </HeaderText>
          ),
        });

        confirmDialogRef.current.setOpen?.call(null, true);
      },
      titleText: 'Add a UPS',
    }),
    [formUtils, setConfirmDialogProps, submitForm, upsTemplate],
  );

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditUpses}
        disableDelete={!hasChecks}
        edit={isEditUpses}
        header
        listEmpty="No Ups(es) registered."
        listItems={upsOverviews}
        onAdd={() => {
          setFormDialogProps(addUpsFormDialogProps);
          formDialogRef.current.setOpen?.call(null, true);
        }}
        onDelete={() => {
          setConfirmDialogProps(
            buildDeleteDialogProps({
              getConfirmDialogTitle: (count) => `Delete ${count} UPSes?`,
              onProceedAppend: () => {
                submitForm({
                  body: { uuids: checks },
                  getErrorMsg: (parentMsg) => (
                    <>Failed to delete UPS(es). {parentMsg}</>
                  ),
                  method: 'delete',
                  url: '/ups',
                });
              },
              renderEntry: ({ key }) => (
                <BodyText>{upsOverviews?.[key].upsName}</BodyText>
              ),
            }),
          );

          confirmDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditUpses((previous) => !previous);
        }}
        onItemCheckboxChange={(key, event, checked) => {
          setCheck(key, checked);
        }}
        onItemClick={(value) => {
          setFormDialogProps(buildEditUpsFormDialogProps(value));
          formDialogRef.current.setOpen?.call(null, true);
        }}
        renderListItemCheckboxState={(key) => getCheck(key)}
        renderListItem={(upsUUID, { upsAgent, upsIPAddress, upsName }) => (
          <FlexBox fullWidth row>
            <BodyText>{upsName}</BodyText>
            <BodyText>agent=&quot;{upsAgent}&quot;</BodyText>
            <BodyText>ip=&quot;{upsIPAddress}&quot;</BodyText>
          </FlexBox>
        )}
      />
    ),
    [
      addUpsFormDialogProps,
      buildDeleteDialogProps,
      buildEditUpsFormDialogProps,
      checks,
      getCheck,
      hasChecks,
      isEditUpses,
      setCheck,
      setConfirmDialogProps,
      setFormDialogProps,
      submitForm,
      upsOverviews,
    ],
  );
  const panelContent = useMemo(
    () =>
      isLoadingUpsTemplate || isUpsOverviewLoading ? <Spinner /> : listElement,
    [isLoadingUpsTemplate, isUpsOverviewLoading, listElement],
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
          <HeaderText>Manage UPSes</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <FormDialog
        {...formDialogProps}
        disableProceed={isFormInvalid}
        loadingAction={isFormSubmitting}
        preActionArea={messageArea}
        ref={formDialogRef}
        showClose
      />
      <ConfirmDialog
        closeOnProceed
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ManageUpsPanel;
