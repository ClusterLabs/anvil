import { Grid } from '@mui/material';
import { useContext, useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import { DialogContext } from '../Dialog';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import IconButton from '../IconButton';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { storageGroupSchema } from './schemas';
import StorageGroupMemberForm from './StorageGroupMemberForm';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const buildFormikInitialValues = (
  storages: APIAnvilSharedStorageOverview,
  sgUuid: string,
  hostUuids: string[],
): StorageGroupFormikValues => {
  const { [sgUuid]: storageGroup } = storages.storageGroups;

  const hosts = hostUuids.reduce<
    Record<string, StorageGroupMemberFormikValues>
  >((previous, hostUuid) => {
    previous[hostUuid] = {
      vg: null,
    };

    return previous;
  }, {});

  const values: StorageGroupFormikValues = {
    hosts,
    name: '',
  };

  if (!storageGroup) {
    return values;
  }

  values.name = storageGroup.name;

  Object.values(storageGroup.members).forEach((member) => {
    const { [member.volumeGroup]: volumeGroup } = storages.volumeGroups;

    const { host: hostUuid, uuid: vgUuid } = volumeGroup;

    hosts[hostUuid].vg = vgUuid;
  });

  return values;
};

const buildRequestBody = (
  values: StorageGroupFormikValues,
  initialValues: StorageGroupFormikValues,
  storages: APIAnvilSharedStorageOverview,
  sgUuid: string,
) => {
  const { [sgUuid]: existing } = storages.storageGroups;

  const requestBody: {
    add: string[];
    name: string;
    remove: string[];
    rename?: string;
  } = {
    add: [],
    name: existing?.name ?? values.name,
    remove: [],
  };

  // Validation ensures the input for storage group name
  if (existing && values.name !== existing.name) {
    // Name changed; set for rename
    requestBody.rename = values.name;
  }

  const { volumeGroups: vgs } = storages;

  Object.keys(values.hosts).forEach((hostUuid) => {
    const { [hostUuid]: before } = initialValues.hosts;

    const { [hostUuid]: after } = values.hosts;

    if (before.vg === after.vg) {
      return;
    }

    if (before.vg) {
      const { [before.vg]: vg } = vgs;

      requestBody.remove.push(vg.internalUuid);
    }

    if (after.vg) {
      const { [after.vg]: vg } = vgs;

      requestBody.add.push(vg.internalUuid);
    }
  });

  return requestBody;
};

const StorageGroupForm: React.FC<StorageGroupFormProps> = (props) => {
  const { anvil: anvilUuid, confirm, storages, uuid: sgUuid = '' } = props;

  const { [sgUuid]: storageGroup } = storages.storageGroups;

  const dialog = useContext(DialogContext);

  const requestUrl = useMemo<string>(
    () => `/anvil/${anvilUuid}/storage`,
    [anvilUuid],
  );

  const hostUuids = useMemo(
    () => Object.keys(storages.hosts),
    [storages.hosts],
  );

  const initialValues = useMemo(
    () => buildFormikInitialValues(storages, sgUuid, hostUuids),
    [hostUuids, sgUuid, storages],
  );

  const submitLabel = useMemo(
    () => (storageGroup ? 'Save' : 'Add'),
    [storageGroup],
  );

  const formikUtils = useFormikUtils<StorageGroupFormikValues>({
    initialValues,
    onSubmit: (values, { setSubmitting }) => {
      let operation: 'Add' | 'Update';
      let requestMethod: 'post' | 'put';

      if (storageGroup) {
        operation = 'Update';
        requestMethod = 'put';
      } else {
        operation = 'Add';
        requestMethod = 'post';
      }

      const requestBody = buildRequestBody(
        values,
        initialValues,
        storages,
        sgUuid,
      );

      confirm.setConfirmDialogProps({
        actionProceedText: operation,
        content: (
          <FormSummary
            entries={requestBody}
            skip={(base, args) => args.key === 'name'}
          />
        ),
        onCancelAppend: () => setSubmitting(false),
        onProceedAppend: () => {
          confirm.setConfirmDialogLoading(true);

          api
            .request({
              data: requestBody,
              method: requestMethod,
              url: requestUrl,
            })
            .then(() => {
              confirm.finishConfirm('Success', {
                children: <>{operation} storage group job registered.</>,
              });

              dialog?.setOpen(false);
            })
            .catch((error) => {
              const emsg = handleAPIError(error);

              emsg.children = (
                <>
                  Failed to {operation.toLocaleLowerCase()} storage group.{' '}
                  {emsg.children}
                </>
              );

              confirm.finishConfirm('Error', emsg);
            });
        },
        titleText: `${operation} ${
          storageGroup?.name ?? values.name
        } with the following?`,
      });

      confirm.setConfirmDialogOpen(true);
    },
    validationSchema: storageGroupSchema(storages, sgUuid),
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      name: 'name',
    }),
    [],
  );

  return (
    <Grid
      component="form"
      container
      onSubmit={(event) => {
        event.preventDefault();

        formik.handleSubmit(event);
      }}
      spacing="1em"
    >
      <Grid item width="100%">
        <Grid alignItems="center" container spacing="1em">
          <Grid item xs>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains.name}
                  label="Storage group name"
                  name={chains.name}
                  onChange={handleChange}
                  value={formik.values.name}
                />
              }
            />
          </Grid>
          <Grid item>
            <IconButton
              disabled={!storageGroup}
              mapPreset="delete"
              onClick={() => {
                formik.setSubmitting(true);

                confirm.setConfirmDialogProps({
                  actionProceedText: 'Delete',
                  content: (
                    <BodyText>
                      This operation will remove the storage group and its
                      relationships to volume groups. It will not remove the
                      actual volume groups.
                    </BodyText>
                  ),
                  onCancelAppend: () => formik.setSubmitting(false),
                  onProceedAppend: () => {
                    confirm.setConfirmDialogLoading(true);

                    const requestBody = {
                      name: storageGroup?.name,
                    };

                    api
                      .request({
                        data: requestBody,
                        method: 'delete',
                        url: requestUrl,
                      })
                      .then(() => {
                        confirm.finishConfirm('Success', {
                          children: <>Delete storage group job registered.</>,
                        });

                        dialog?.setOpen(false);
                      })
                      .catch((error) => {
                        const emsg = handleAPIError(error);

                        emsg.children = (
                          <>Failed to delete storage group. {emsg.children}</>
                        );

                        confirm.finishConfirm('Error', emsg);
                      });
                  },
                  proceedColour: 'red',
                  titleText: `Delete ${storageGroup?.name}?`,
                });

                confirm.setConfirmDialogOpen(true);
              }}
              size="small"
              variant="redcontained"
            />
          </Grid>
        </Grid>
      </Grid>
      {hostUuids.map((uuid) => (
        <Grid item key={`member-on-host-${uuid}`} width="100%">
          <StorageGroupMemberForm
            formikUtils={formikUtils}
            host={uuid}
            storages={storages}
          />
        </Grid>
      ))}
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ActionGroup
          actions={[
            {
              background: 'blue',
              children: submitLabel,
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default StorageGroupForm;
