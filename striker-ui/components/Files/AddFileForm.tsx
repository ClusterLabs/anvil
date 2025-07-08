import { AxiosRequestConfig } from 'axios';
import { useCallback, useMemo, useRef, useState } from 'react';
import { v4 as uuidv4 } from 'uuid';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import ContainedButton from '../ContainedButton';
import FileInputGroup from './FileInputGroup';
import FlexBox from '../FlexBox';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup from '../MessageGroup';
import fileListSchema from './schema';
import UploadFileProgress from './UploadFileProgress';
import useFormikUtils from '../../hooks/useFormikUtils';

const REQUEST_INCOMPLETE_UPLOAD_LIMIT = 99;

const setUploadProgress: (
  previous: UploadFiles | undefined,
  uuid: keyof UploadFiles,
  progress: UploadFiles[string]['progress'],
) => UploadFiles | undefined = (previous, uuid, progress) => {
  if (!previous) return previous;

  previous[uuid].progress = progress;

  return { ...previous };
};

const AddFileForm: React.FC<AddFileFormProps> = (props) => {
  const { anvils, drHosts } = props;

  const filePickerRef = useRef<HTMLInputElement>(null);

  const [messages, setMessages] = useState<Messages>({});

  const [uploads, setUploads] = useState<UploadFiles | undefined>();

  const setApiMessage = useCallback(
    (msg?: Message) =>
      setMessages((previous) => {
        const { api: rm, ...shallow } = previous;

        if (msg) {
          shallow.api = msg;
        }

        return shallow;
      }),
    [],
  );

  const formikUtils = useFormikUtils<FileFormikValues>({
    initialValues: {},
    onSubmit: (values) => {
      const files = Object.values(values);

      setUploads(
        files.reduce<UploadFiles>((previous, { file, name, uuid }) => {
          if (!file) return previous;

          previous[uuid] = { name, progress: 0, uuid };

          return previous;
        }, {}),
      );

      setApiMessage({
        children: (
          <>
            Closing this dialog before the upload(s) complete will cancel the
            upload(s).
          </>
        ),
      });

      const promises = files.reduce<Promise<void>[]>(
        (chain, { file, name, uuid }) => {
          if (!file) return chain;

          const data = new FormData();

          data.append('file', new File([file], name, { ...file }));

          const promise = api
            .post('/file', data, {
              headers: {
                'Content-Type': 'multipart/form-data',
              },
              onUploadProgress: (
                (
                  fileUuid: string,
                ): AxiosRequestConfig<FormData>['onUploadProgress'] =>
                (progressEvent) => {
                  // Make the ratio 1 when total isn't available; the upload
                  // limit will prevent progress from reaching 100 until the
                  // request completes.
                  const { loaded, total = loaded } = progressEvent;

                  setUploads((previous) =>
                    setUploadProgress(
                      previous,
                      fileUuid,
                      Math.round(
                        (loaded / total) * REQUEST_INCOMPLETE_UPLOAD_LIMIT,
                      ),
                    ),
                  );
                }
              )(uuid),
            })
            .then(
              ((fileUuid: string) => () => {
                setUploads((previous) =>
                  setUploadProgress(previous, fileUuid, 100),
                );
              })(uuid),
            );

          chain.push(promise);

          return chain;
        },
        [],
      );

      Promise.all(promises)
        .then(() => {
          setApiMessage({
            children: (
              <FlexBox spacing={0}>
                <span>
                  Upload(s) completed; file(s) will be listed after the job(s)
                  to sync them to other host(s) finish.
                </span>
                <span>You can close this dialog.</span>
              </FlexBox>
            ),
          });
        })
        .catch((error) => {
          const emsg = handleAPIError(error);

          emsg.children = <>Failed to add file. {emsg.children}</>;

          setApiMessage(emsg);
        });
    },
    validationSchema: fileListSchema,
  });

  const { disabledSubmit, formik, formikErrors } = formikUtils;

  const handleSelectFiles = useCallback<
    React.ChangeEventHandler<HTMLInputElement>
  >(
    (event) => {
      const {
        target: { files },
      } = event;

      if (!files) return;

      const values = Array.from(files).reduce<FileFormikValues>(
        (previous, file) => {
          const fileUuid = uuidv4();

          previous[fileUuid] = {
            file,
            name: file.name,
            uuid: fileUuid,
          };

          return previous;
        },
        {},
      );

      formik.setValues(values, true);
    },
    [formik],
  );

  const fileInputs = useMemo<React.ReactElement[]>(
    () =>
      Object.values<FileFormikFile>(formik.values).map((file) => {
        const { uuid: fileUuid } = file;

        return (
          <FileInputGroup
            anvils={anvils}
            drHosts={drHosts}
            fileUuid={fileUuid}
            formik={formik}
            key={fileUuid}
          />
        );
      }),
    [anvils, drHosts, formik],
  );

  return (
    <FlexBox>
      <MessageGroup messages={messages} />
      {uploads ? (
        <UploadFileProgress uploads={uploads} />
      ) : (
        <FlexBox
          component="form"
          onSubmit={(event) => {
            event.preventDefault();

            formik.submitForm();
          }}
        >
          <input
            id="files"
            multiple
            name="files"
            onChange={handleSelectFiles}
            ref={(input) => {
              // Assigning the ref alone makes the ref always null, probably due
              // to a mix of the periodic updates and conditional rendering.
              //
              // Use the callback style to ensure the assignment is done every
              // render.
              filePickerRef.current = input;
            }}
            style={{ display: 'none' }}
            type="file"
          />
          <ContainedButton
            onClick={() => {
              filePickerRef.current?.click();
            }}
          >
            Browse
          </ContainedButton>
          {fileInputs}
          <MessageGroup count={1} messages={formikErrors} />
          <ActionGroup
            actions={[
              {
                background: 'blue',
                children: 'Add',
                disabled: disabledSubmit,
                type: 'submit',
              },
            ]}
          />
        </FlexBox>
      )}
    </FlexBox>
  );
};

export default AddFileForm;
