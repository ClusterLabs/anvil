import { useFormik } from 'formik';
import { FC, useCallback, useMemo, useRef } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import convertFormikErrorsToMessages from '../../lib/convertFormikErrorsToMessages';
import FileInputGroup from './FileInputGroup';
import FlexBox from '../FlexBox';
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
  const { anvils, drHosts, previous: file } = props;

  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const setApiMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 'api', message),
    [],
  );

  const formikInitialValues = useMemo<FileFormikValues>(() => {
    const { locations, name, type, uuid } = file;

    return {
      [uuid]: {
        locations: Object.values(locations).reduce<FileFormikLocations>(
          (previous, { active, anvilUuid, hostUuid }) => {
            let category: keyof FileFormikLocations = 'anvils';
            let id = anvilUuid;

            if (hostUuid in drHosts) {
              category = 'drHosts';
              id = hostUuid;
            }

            previous[category][id] = { active };

            return previous;
          },
          { anvils: {}, drHosts: {} },
        ),
        name,
        type,
        uuid,
      },
    };
  }, [drHosts, file]);

  const formik = useFormik<FileFormikValues>({
    initialValues: formikInitialValues,
    onSubmit: (values, { setSubmitting }) => {
      const body = toEditFileRequestBody(values[file.uuid], file);

      api
        .put(`/file/${file.uuid}`, body)
        .then(() => {
          setApiMessage({ children: <>File updated.</> });
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
    () => convertFormikErrorsToMessages(formik.errors),
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
