type FileFormikLocations = {
  anvils: {
    [anvilUuid: string]: {
      active: boolean;
    };
  };
  drHosts: {
    [hostUuid: string]: {
      active: boolean;
    };
  };
};

type FileFormikFile = {
  file?: File;
  locations?: FileFormikLocations;
  name: string;
  type?: FileType;
  uuid: string;
};

type FileFormikValues = {
  [fileUuid: string]: FileFormikFile;
};

/** ---------- Component types ---------- */

/** FileInputGroup */

type FileInputGroupOptionalProps = {
  showSyncInputGroup?: boolean;
  showTypeInput?: boolean;
};

type FileInputGroupProps = FileInputGroupOptionalProps & {
  anvils: APIAnvilOverviewList;
  drHosts: APIHostOverviewList;
  fileUuid: string;
  formik: Formik<FileFormikValues>;
};

/** AddFileForm */

type UploadFiles = {
  [fileUuid: string]: Pick<FileFormikFile, 'name' | 'uuid'> & {
    progress: number;
  };
};

type AddFileFormProps = Pick<FileInputGroupProps, 'anvils' | 'drHosts'>;

/** EditFileForm */

type EditFileFormProps = Pick<FileInputGroupProps, 'anvils' | 'drHosts'> & {
  onSuccess?: () => void;
  previous: APIFileDetail;
};

/** UploadFileProgress */

type UploadFileProgressProps = {
  uploads: UploadFiles;
};
