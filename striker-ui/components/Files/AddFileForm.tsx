import { AxiosRequestConfig } from 'axios';
import { useFormik } from 'formik';
import {
  ChangeEventHandler,
  FC,
  ReactElement,
  useCallback,
  useMemo,
  useRef,
  useState,
} from 'react';
import { v4 as uuidv4 } from 'uuid';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import ContainedButton from '../ContainedButton';
import FileInputGroup from './FileInputGroup';
import FlexBox from '../FlexBox';
import getFormikErrorMessages from '../../lib/getFormikErrorMessages';
import handleAPIError from '../../lib/handleAPIError';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import fileListSchema from './schema';
import UploadFileProgress from './UploadFileProgress';

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

const AddFileForm: FC<AddFileFormProps> = (props) => {
  const { anvils, drHosts } = props;

  const messageGroupRef = useRef<MessageGroupForwardedRefContent>(null);

  const filePickerRef = useRef<HTMLInputElement>(null);

  const [uploads, setUploads] = useState<UploadFiles | undefined>();

  const setApiMessage = useCallback(
    (msg?: Message) =>
      messageGroupRef?.current?.setMessage?.call(null, 'api', msg),
    [],
  );

  const formik = useFormik<FileFormikValues>({
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

  const handleSelectFiles = useCallback<ChangeEventHandler<HTMLInputElement>>(
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

      formik.setValues(values);
    },
    [formik],
  );

  const fileInputs = useMemo<ReactElement[]>(
    () =>
      formik.values &&
      Object.values(formik.values).map((file) => {
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
      <MessageGroup ref={messageGroupRef} />
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
            ref={filePickerRef}
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
                disabled: disableProceed,
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
