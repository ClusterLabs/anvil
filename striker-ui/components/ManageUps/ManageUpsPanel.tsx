import { useMemo, useRef, useState } from 'react';

import { DialogWithHeader } from '../Dialog';
import FlexBox from '../FlexBox';
import handleFormSubmit from '../Form/handleFormSubmit';
import List from '../List';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText, InlineMonoText } from '../Text';
import UpsForm, { AddOrEditUpsRequestBody } from './UpsForm';
import UpsInputGroup from './UpsInputGroup';
import getUpsFormikInitialValues from './getUpsFormikInitialValues';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';
import useFormUtils from '../../hooks/useFormUtils';
import buildUpsSchema from './schemas/buildUpsSchema';

import {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_ID_UPS_TYPE,
} from './inputIds';

const ManageUpsPanel: React.FC = () => {
  const addDialogRef = useRef<DialogForwardedRefContent | null>(null);
  const editDialogRef = useRef<DialogForwardedRefContent | null>(null);

  const confirm = useConfirmDialog();

  const [isEditUpses, setIsEditUpses] = useState<boolean>(false);

  const [editUuid, setEditUuid] = useState<string>('');

  const { data: upsTemplate, loading: isLoadingUpsTemplate } =
    useFetch<APIUpsTemplate>('/ups/template');

  const { data: upsOverviews, loading: isUpsOverviewLoading } =
    useFetch<APIUpsOverviewList>(`/ups`, {
      refreshInterval: 60000,
    });

  const editTarget = upsOverviews?.[editUuid];

  const { buildDeleteDialogProps, checks, getCheck, hasChecks, setCheck } =
    useChecklist({
      list: upsOverviews,
    });

  const deleteUtils = useFormUtils([]);

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
          addDialogRef.current?.setOpen(true);
        }}
        onDelete={() => {
          confirm.setConfirmDialogProps(
            buildDeleteDialogProps({
              getConfirmDialogTitle: (count) => `Delete ${count} UPSes?`,
              onProceedAppend: () => {
                deleteUtils.submitForm({
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

          confirm.setConfirmDialogOpen(true);
        }}
        onEdit={() => {
          setIsEditUpses((previous) => !previous);
        }}
        onItemCheckboxChange={(key, event, checked) => {
          setCheck(key, checked);
        }}
        onItemClick={(value) => {
          setEditUuid(value.upsUUID);

          editDialogRef.current?.setOpen(true);
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
      buildDeleteDialogProps,
      checks,
      confirm,
      deleteUtils,
      getCheck,
      hasChecks,
      isEditUpses,
      setCheck,
      upsOverviews,
    ],
  );

  const panelContent = useMemo(
    () =>
      isLoadingUpsTemplate || isUpsOverviewLoading ? <Spinner /> : listElement,
    [isLoadingUpsTemplate, isUpsOverviewLoading, listElement],
  );

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage UPSes</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <DialogWithHeader header="Add a UPS" ref={addDialogRef} showClose wide>
        {upsOverviews && upsTemplate && (
          <UpsForm
            config={{
              initialValues: getUpsFormikInitialValues(upsTemplate),
              onSubmit: (values, helpers) => {
                const {
                  [INPUT_ID_UPS_IP]: ipAddress,
                  [INPUT_ID_UPS_NAME]: name,
                  [INPUT_ID_UPS_TYPE]: typeId,
                } = values;

                const { agent, brand } = upsTemplate[typeId];

                handleFormSubmit({
                  confirm,
                  getRequestBody: (): AddOrEditUpsRequestBody => ({
                    agent,
                    brand,
                    ipAddress,
                    name,
                    typeId,
                    uuid: '',
                  }),
                  getSummary: () => ({
                    brand,
                    name,
                    ipAddress,
                  }),
                  header: (
                    <HeaderText>
                      Add a{' '}
                      <InlineMonoText fontSize="inherit">
                        {brand}
                      </InlineMonoText>{' '}
                      UPS with the following data?
                    </HeaderText>
                  ),
                  helpers,
                  onError: () => `Failed to add UPS.`,
                  onSuccess: () => `Successfully added UPS ${name}`,
                  operation: 'add',
                  url: `/ups`,
                  values,
                });
              },
              validationSchema: buildUpsSchema(upsOverviews, upsTemplate),
            }}
            operation="add"
          >
            <UpsInputGroup upsTemplate={upsTemplate} />
          </UpsForm>
        )}
      </DialogWithHeader>
      <DialogWithHeader
        header={
          editTarget && (
            <HeaderText>
              Update UPS{' '}
              <InlineMonoText fontSize="inherit">
                {editTarget.upsName}
              </InlineMonoText>
            </HeaderText>
          )
        }
        ref={editDialogRef}
        showClose
        wide
      >
        {upsOverviews && upsTemplate && editTarget && (
          <UpsForm
            config={{
              initialValues: getUpsFormikInitialValues(upsTemplate, editTarget),
              onSubmit: (values, helpers) => {
                const {
                  [INPUT_ID_UPS_IP]: ipAddress,
                  [INPUT_ID_UPS_NAME]: name,
                  [INPUT_ID_UPS_TYPE]: typeId,
                } = values;

                const { agent, brand } = upsTemplate[typeId];

                handleFormSubmit({
                  confirm,
                  getRequestBody: (): AddOrEditUpsRequestBody => ({
                    agent,
                    brand,
                    ipAddress,
                    name,
                    typeId,
                    uuid: editTarget.upsUUID,
                  }),
                  getSummary: () => ({
                    brand,
                    name,
                    ipAddress,
                    uuid: editTarget.upsUUID,
                  }),
                  header: (
                    <HeaderText>
                      Update{' '}
                      <InlineMonoText fontSize="inherit">{name}</InlineMonoText>{' '}
                      with the following data?
                    </HeaderText>
                  ),
                  helpers,
                  onError: () => `Failed to update UPS.`,
                  onSuccess: () =>
                    `Successfully updated UPS ${editTarget.upsName}`,
                  operation: 'edit',
                  url: `/ups/${editTarget.upsUUID}`,
                  values,
                });
              },
              validationSchema: buildUpsSchema(
                upsOverviews,
                upsTemplate,
                editTarget.upsUUID,
              ),
            }}
            operation="edit"
          >
            <UpsInputGroup upsTemplate={upsTemplate} />
          </UpsForm>
        )}
      </DialogWithHeader>
      {confirm.confirmDialog}
    </>
  );
};

export default ManageUpsPanel;
