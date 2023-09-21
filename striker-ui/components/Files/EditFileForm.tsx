import { useFormik } from 'formik';
import { FC, useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import convertFormikErrorsToMessages from '../../lib/convertFormikErrorsToMessages';
import FileInputGroup from './FileInputGroup';
import FlexBox from '../FlexBox';
import MessageGroup from '../MessageGroup';
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
    onSubmit: (values) => {
      const body = toEditFileRequestBody(values[file.uuid], file);

      api.put(`/file/${file.uuid}`, body);
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
      <MessageGroup count={1} messages={formikErrors} />
      <ActionGroup
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
