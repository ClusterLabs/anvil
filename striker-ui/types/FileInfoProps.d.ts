declare type FileInfoProps = {
  fileName: string;
  fileType: UploadFileType;
  fileSyncAnvils: Array<{
    anvilName: string;
    anvilDescription: string;
    anvilUUID: string;
    isSync: boolean;
  }>;
  onChange?: (inputValues: Partial<FileInfoMetadata>) => void;
};
