import { ChangeEventHandler, useEffect, useRef, useState } from 'react';
import { Box, Button, Input, InputLabel } from '@mui/material';
import EventEmitter from 'events';

import { UPLOAD_FILE_TYPES } from '../../lib/consts/UPLOAD_FILE_TYPES';

import FileInfo from './FileInfo';
import { BodyText } from '../Text';

type FileUploadInfoProps = {
  openFilePickerEventEmitter?: EventEmitter;
};

const FILE_UPLOAD_INFO_DEFAULT_PROPS = {
  openFilePickerEventEmitter: undefined,
};

const FileUploadInfo = ({
  openFilePickerEventEmitter,
}: FileUploadInfoProps = FILE_UPLOAD_INFO_DEFAULT_PROPS): JSX.Element => {
  const selectFileRef = useRef<HTMLInputElement>();

  const [selectedFileList, setSelectedFileList] = useState<File[]>([]);

  const convertMIMETypeToFileTypeKey = (
    fileMIMEType: string,
  ): UploadFileTypes => {
    const fileTypesIterator = UPLOAD_FILE_TYPES.entries();

    let fileType: UploadFileTypes | undefined;

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
      setSelectedFileList(Array.from(files));
    }
  };

  useEffect(() => {
    openFilePickerEventEmitter?.addListener('open', () => {
      selectFileRef.current?.click();
    });
  }, [openFilePickerEventEmitter]);

  return (
    <form encType="multipart/form-data">
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
        {selectedFileList.map((file: File) => (
          <FileInfo
            fileName={file.name}
            fileType={convertMIMETypeToFileTypeKey(file.type)}
            fileSyncAnvilList={[]}
            key={file.name}
          />
        ))}
        {selectedFileList.length > 0 && (
          <Button sx={{ textTransform: 'none' }}>
            <BodyText text="Upload" />
          </Button>
        )}
      </Box>
    </form>
  );
};

FileUploadInfo.defaultProps = FILE_UPLOAD_INFO_DEFAULT_PROPS;

export default FileUploadInfo;
