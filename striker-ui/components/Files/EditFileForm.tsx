import { useFormik } from 'formik';
import { FC, useCallback, useMemo, useRef } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import FileInputGroup from './FileInputGroup';
import FlexBox from '../FlexBox';
import getFormikErrorMessages from '../../lib/getFormikErrorMessages';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import fileListSchema from './schema';

const toEditFileRequestBody = (
  file: FileFormikFile,
  pfile: APIFileDetail,
): APIEditFileRequestBody | undefined => {
  const { locations, name: fileName, type: fileType, uuid: fileUUID } = file;

  if (!locations || !fileType) return undefined;

  const fileLocations: APIEditFileRequestBody['fileLocations'] = [];

  Object.entries(locations.anvils).reduce<
    APIEditFileRequestBody['fileLocations']
  >((previous, [anvilUuid, { active: isFileLocationActive }]) => {
    const {
      anvils: {
        [anvilUuid]: { locationUuids },
      },
    } = pfile;

    const current = locationUuids.map<
      APIEditFileRequestBody['fileLocations'][number]
    >((fileLocationUUID) => ({
      fileLocationUUID,
      isFileLocationActive,
    }));

    previous.push(...current);

    return previous;
  }, fileLocations);

  Object.entries(locations.drHosts).reduce<
    APIEditFileRequestBody['fileLocations']
  >((previous, [drHostUuid, { active: isFileLocationActive }]) => {
    const {
      hosts: {
        [drHostUuid]: { locationUuids },
      },
    } = pfile;

    const current = locationUuids.map<
      APIEditFileRequestBody['fileLocations'][number]
    >((fileLocationUUID) => ({
      fileLocationUUID,
      isFileLocationActive,
    }));

    previous.push(...current);

    return previous;
  }, fileLocations);

  return { fileLocations, fileName, fileType, fileUUID };
};

const EditFileForm: FC<EditFileFormProps> = (props) => {
  const { anvils, drHosts, onSuccess, previous: file } = props;

  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const setApiMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 'api', message),
    [],
  );

  const formikInitialValues = useMemo<FileFormikValues>(() => {
    const { name, type, uuid } = file;

    const locations: FileFormikLocations = { anvils: {}, drHosts: {} };

    Object.values(anvils).forEach((anvil) => {
      const active = file.anvils[anvil.uuid].locationUuids.every(
        (locationUuid) => file.locations[locationUuid].active,
      );

      locations.anvils[anvil.uuid] = { active };
    });

    const locationValues = Object.values(file.locations);

    Object.values(drHosts).forEach((dr) => {
      const found = locationValues.find(
        (value) => value.hostUuid === dr.hostUUID,
      );

      locations.drHosts[dr.hostUUID] = { active: found ? found.active : false };
    });

    return {
      [uuid]: {
        locations,
        name,
        type,
        uuid,
      },
    };
  }, [anvils, drHosts, file]);

  const formik = useFormik<FileFormikValues>({
    initialValues: formikInitialValues,
    onSubmit: (values, { setSubmitting }) => {
      const body = toEditFileRequestBody(values[file.uuid], file);

      api
        .put(`/file/${file.uuid}`, body)
        .then(() => {
          setApiMessage({ children: <>File updated.</> });

          onSuccess?.call(null);
        })
        .catch((error) => {
          const emsg = handleAPIError(error);

          emsg.children = <>Failed to modify file. {emsg.children}</>;

          setApiMessage(emsg);
        })
        .finally(() => {
          setSubmitting(false);
        });
    },
    validationSchema: fileListSchema,
  });

  const formikErrors = useMemo<Messages>(
    () => getFormikErrorMessages(formik.errors),
    [formik.errors],
  );

  const disableProceed = useMemo<boolean>(
    () =>
      !formik.dirty ||
      !formik.isValid ||
      formik.isValidating ||
      formik.isSubmitting,
    [formik.dirty, formik.isSubmitting, formik.isValid, formik.isValidating],
  );

  return (
    <FlexBox
      component="form"
      onSubmit={(event) => {
        event.preventDefault();

        formik.submitForm();
      }}
    >
      <FileInputGroup
        anvils={anvils}
        drHosts={drHosts}
        fileUuid={file.uuid}
        formik={formik}
        showSyncInputGroup
        showTypeInput
      />
      <MessageGroup count={1} messages={formikErrors} ref={messageGroupRef} />
      <ActionGroup
        loading={formik.isSubmitting}
        actions={[
          {
            background: 'blue',
            children: 'Edit',
            disabled: disableProceed,
            type: 'submit',
          },
        ]}
      />
    </FlexBox>
  );
};

export default EditFileForm;
