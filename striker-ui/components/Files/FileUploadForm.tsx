import EventEmitter from 'events';
import {
  ChangeEventHandler,
  FormEventHandler,
  useEffect,
  useRef,
  useState,
} from 'react';
import { Box, Input, InputLabel } from '@mui/material';

import { UPLOAD_FILE_TYPES } from '../../lib/consts/UPLOAD_FILE_TYPES';

import { ProgressBar } from '../Bars';
import ContainedButton from '../ContainedButton';
import FileInfo from './FileInfo';
import MessageBox from '../MessageBox';
import { BodyText } from '../Text';

import mainAxiosInstance from '../../lib/singletons/mainAxiosInstance';

type FileUploadFormProps = {
  onFileUploadComplete?: () => void;
  eventEmitter?: EventEmitter;
};

type SelectedFile = Pick<
  FileDetailMetadata,
  'fileName' | 'fileLocations' | 'fileType'
> & {
  file: File;
};

type InUploadFile = Pick<FileDetailMetadata, 'fileName'> & {
  progressValue: number;
};

const FILE_UPLOAD_FORM_DEFAULT_PROPS: Partial<FileUploadFormProps> = {
  onFileUploadComplete: undefined,
  eventEmitter: undefined,
};

const FileUploadForm = (
  {
    onFileUploadComplete,
    eventEmitter,
  }: FileUploadFormProps = FILE_UPLOAD_FORM_DEFAULT_PROPS as FileUploadFormProps,
): JSX.Element => {
  const selectFileRef = useRef<HTMLInputElement>();

  const [selectedFiles, setSelectedFiles] = useState<SelectedFile[]>([]);
  const [inUploadFiles, setInUploadFiles] = useState<InUploadFile[]>([]);

  const convertMIMETypeToFileTypeKey = (fileMIMEType: string): FileType => {
    const fileTypesIterator = UPLOAD_FILE_TYPES.entries();

    let fileType: FileType | undefined;

    do {
      const fileTypesResult = fileTypesIterator.next();

      if (fileTypesResult.value) {
        const [fileTypeKey, [mimeTypeToUse]] = fileTypesResult.value;

        if (fileMIMEType === mimeTypeToUse) {
          fileType = fileTypeKey;
        }
      } else {
        fileType = 'other';
      }
    } while (!fileType);

    return fileType;
  };

  const autocompleteAfterSelectFile: ChangeEventHandler<HTMLInputElement> = ({
    target: { files },
  }) => {
    if (files) {
      setSelectedFiles(
        Array.from(files).map(
          (file): SelectedFile => ({
            file,
            fileName: file.name,
            fileLocations: [],
            fileType: convertMIMETypeToFileTypeKey(file.type),
          }),
        ),
      );
    }
  };

  const generateFileInfoOnChangeHandler =
    (fileIndex: number): FileInfoChangeHandler =>
    (inputValues) => {
      selectedFiles[fileIndex] = {
        ...selectedFiles[fileIndex],
        ...inputValues,
      };
    };

  const uploadFiles: FormEventHandler<HTMLFormElement> = (event) => {
    event.preventDefault();

    while (selectedFiles.length > 0) {
      const selectedFile = selectedFiles.shift();

      if (selectedFile) {
        const { file, fileName } = selectedFile;

        const fileFormData = new FormData();

        fileFormData.append('file', new File([file], fileName, { ...file }));
        // Re-add when the back-end tools can support changing file type on file upload.
        // Note: get file type from destructuring selectedFile.
        // fileFormData.append('file-type', fileType);

        const inUploadFile: InUploadFile = { fileName, progressValue: 0 };
        inUploadFiles.push(inUploadFile);

        mainAxiosInstance
          .post('/file', fileFormData, {
            headers: {
              'Content-Type': 'multipart/form-data',
            },
            onUploadProgress: ({ loaded, total }) => {
              inUploadFile.progressValue = Math.round((loaded / total) * 100);
              setInUploadFiles([...inUploadFiles]);
            },
          })
          .then(() => {
            onFileUploadComplete?.call(null);

            inUploadFiles.splice(inUploadFiles.indexOf(inUploadFile), 1);
            setInUploadFiles([...inUploadFiles]);
          });
      }
    }

    // Clears "staging area" (selected files) and populates "in-progress area" (in-upload files).
    setSelectedFiles([]);
    setInUploadFiles([...inUploadFiles]);
  };

  useEffect(() => {
    eventEmitter?.addListener('openFilePicker', () => {
      selectFileRef.current?.click();
    });

    eventEmitter?.addListener('clearSelectedFiles', () => {
      setSelectedFiles([]);
    });
  }, [eventEmitter]);

  return (
    <form onSubmit={uploadFiles}>
      <InputLabel htmlFor="select-file">
        <Input
          id="select-file"
          inputProps={{ multiple: true }}
          onChange={autocompleteAfterSelectFile}
          ref={selectFileRef}
          sx={{ display: 'none' }}
          type="file"
        />
      </InputLabel>
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
        {inUploadFiles.map(({ fileName, progressValue }) => (
          <Box
            key={`in-upload-${fileName}`}
            sx={{
              alignItems: { md: 'center' },
              display: 'flex',
              flexDirection: { xs: 'column', md: 'row' },
              '& > :first-child': {
                minWidth: 100,
                overflow: 'hidden',
                overflowWrap: 'normal',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap',
                width: { xs: '100%', md: 200 },
                wordBreak: 'keep-all',
              },
              '& > :last-child': { flexGrow: 1 },
            }}
          >
            <BodyText text={fileName} />
            <ProgressBar progressPercentage={progressValue} />
          </Box>
        ))}
      </Box>
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          '& > :not(:first-child)': { marginTop: '1em' },
        }}
      >
        {selectedFiles.length > 0 && (
          <MessageBox
            text="Uploaded files will be listed automatically, but it may take a while for larger files to appear."
            type="info"
          />
        )}
        {selectedFiles.map(
          (
            {
              file: { name: originalFileName },
              fileName,
              // Re-add when the back-end tools can support changing file type on file upload.
              // Note: file type must be supplied to FileInfo.
              // fileType,
              fileLocations,
            },
            fileIndex,
          ) => (
            <FileInfo
              {...{ fileName, fileLocations }}
              // Use a non-changing key to prevent recreating the component.
              // fileName holds the string from the file-name input, thus it changes when users makes a change.
              key={`selected-${originalFileName}`}
              onChange={generateFileInfoOnChangeHandler(fileIndex)}
            />
          ),
        )}
        {selectedFiles.length > 0 && (
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'row',
              justifyContent: 'flex-end',
            }}
          >
            <ContainedButton type="submit">Upload</ContainedButton>
          </Box>
        )}
      </Box>
    </form>
  );
};

FileUploadForm.defaultProps = FILE_UPLOAD_FORM_DEFAULT_PROPS;

export default FileUploadForm;
