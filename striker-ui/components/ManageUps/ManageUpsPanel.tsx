import { useRef, useState } from 'react';

import { DialogWithHeader } from '../Dialog';
import FlexBox from '../FlexBox';
import handleFormSubmit from '../Form/handleFormSubmit';
import List from '../List';
import { Panel, PanelHeader } from '../Panels';
import { BodyText, HeaderText, InlineMonoText } from '../Text';
import UpsForm, { CreateOrUpdateUpsRequestBody } from './UpsForm';
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

  const { data: upsTemplate, loading: loadingUpsTemplate } =
    useFetch<APIUpsTemplate>('/ups/template');

  const {
    data: upses,
    loading: loadingUpses,
    mutate: getUpses,
  } = useFetch<APIUpsOverviewList>(`/ups`, {
    refreshInterval: 60000,
  });

  const editTarget = upses?.[editUuid];

  const {
    buildDeleteDialogProps,
    checks,
    getCheck,
    hasChecks,
    resetChecks,
    setCheck,
  } = useChecklist({
    list: upses,
  });

  const deleteUtils = useFormUtils([]);

  const loadingAll = loadingUpses || loadingUpsTemplate;

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage UPSes</HeaderText>
        </PanelHeader>
        <List
          allowEdit
          allowItemButton={isEditUpses}
          disableDelete={!hasChecks}
          edit={isEditUpses}
          header
          listEmpty="No Ups(es) registered."
          listItems={upses}
          loading={loadingUpses}
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
                    getErrorMsg: (parentMsg) => {
                      confirm.finishConfirm('Error', {
                        children: `Failed to delete UPS(es). ${parentMsg}`,
                      });

                      return null;
                    },
                    method: 'delete',
                    onSuccess: () => {
                      resetChecks();

                      getUpses();

                      confirm.setConfirmDialogOpen(false);
                    },
                    url: '/ups',
                  });
                },
                renderEntry: ({ key }) => (
                  <BodyText>{upses?.[key].upsName}</BodyText>
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
      </Panel>
      <DialogWithHeader
        header="Add a UPS"
        loading={loadingAll}
        ref={addDialogRef}
        showClose
        wide
      >
        {upses && upsTemplate && (
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
                  getRequestBody: (): CreateOrUpdateUpsRequestBody => ({
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
                    <HeaderText>Add a UPS with the following data?</HeaderText>
                  ),
                  helpers,
                  onError: () => `Failed to add UPS.`,
                  onSuccess: () => {
                    getUpses();

                    addDialogRef.current?.setOpen(false);

                    return `Successfully added UPS ${name}`;
                  },
                  operation: 'add',
                  url: `/ups`,
                  values,
                });
              },
              validationSchema: buildUpsSchema(upses, upsTemplate),
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
        loading={loadingAll}
        ref={editDialogRef}
        showClose
        wide
      >
        {upses && upsTemplate && editTarget && (
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
                  getRequestBody: (): CreateOrUpdateUpsRequestBody => ({
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
                  onSuccess: () => {
                    getUpses();

                    editDialogRef.current?.setOpen(false);

                    return `Successfully updated UPS ${editTarget.upsName}`;
                  },
                  operation: 'edit',
                  url: `/ups/${editTarget.upsUUID}`,
                  values,
                });
              },
              validationSchema: buildUpsSchema(
                upses,
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
