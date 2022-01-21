import {
  ChangeEventHandler,
  FormEventHandler,
  useEffect,
  useRef,
  useState,
} from 'react';
import { Box, Button, Input, InputLabel } from '@mui/material';
import EventEmitter from 'events';

import { UPLOAD_FILE_TYPES } from '../../lib/consts/UPLOAD_FILE_TYPES';

import FileInfo from './FileInfo';
import { ProgressBar } from '../Bars';
import { BodyText } from '../Text';
import mainAxiosInstance from '../../lib/singletons/mainAxiosInstance';

type FileUploadFormProps = {
  onFileUploadComplete?: () => void;
  openFilePickerEventEmitter?: EventEmitter;
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
  openFilePickerEventEmitter: undefined,
};

const FileUploadForm = (
  {
    onFileUploadComplete,
    openFilePickerEventEmitter,
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

  const generateFileInfoOnChangeHandler = (
    fileIndex: number,
  ): FileInfoChangeHandler => (inputValues) => {
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
        const { file, fileName, fileType } = selectedFile;

        const fileFormData = new FormData();

        fileFormData.append('file', new File([file], fileName, { ...file }));
        fileFormData.append('file-type', fileType);

        const inUploadFile: InUploadFile = { fileName, progressValue: 0 };
        inUploadFiles.push(inUploadFile);

        mainAxiosInstance
          .post('/files', fileFormData, {
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
    openFilePickerEventEmitter?.addListener('open', () => {
      selectFileRef.current?.click();
    });
  }, [openFilePickerEventEmitter]);

  return (
    <form onSubmit={uploadFiles}>
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
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
        {inUploadFiles.map(({ fileName, progressValue }) => (
          <Box
            key={`in-upload-${fileName}`}
            sx={{ display: 'flex', flexDirection: 'row' }}
          >
            <BodyText text={fileName} />
            <Box sx={{ flexGrow: 1 }}>
              <ProgressBar progressPercentage={progressValue} />
            </Box>
          </Box>
        ))}
        {selectedFiles.map(
          (
            {
              file: { name: originalFileName },
              fileName,
              fileType,
              fileLocations,
            },
            fileIndex,
          ) => (
            <FileInfo
              {...{ fileName, fileType, fileLocations }}
              // Use a non-changing key to prevent recreating the component.
              // fileName holds the string from the file-name input, thus it changes when users makes a change.
              key={`selected-${originalFileName}`}
              onChange={generateFileInfoOnChangeHandler(fileIndex)}
            />
          ),
        )}
        {selectedFiles.length > 0 && (
          <Button sx={{ textTransform: 'none' }} type="submit">
            <BodyText text="Upload" />
          </Button>
        )}
      </Box>
    </form>
  );
};

FileUploadForm.defaultProps = FILE_UPLOAD_FORM_DEFAULT_PROPS;

export default FileUploadForm;
