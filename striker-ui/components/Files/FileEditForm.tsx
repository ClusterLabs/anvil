import { AxiosResponse } from 'axios';
import {
  FormEventHandler,
  MouseEventHandler,
  useEffect,
  useState,
} from 'react';
import { Box, Checkbox, checkboxClasses } from '@mui/material';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { GREY, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';

import ConfirmDialog from '../ConfirmDialog';
import ContainedButton from '../ContainedButton';
import FileInfo from './FileInfo';
import Spinner from '../Spinner';

import fetchJSON from '../../lib/fetchers/fetchJSON';
import mainAxiosInstance from '../../lib/singletons/mainAxiosInstance';

type ReducedFileLocation = Partial<
  Pick<FileLocation, 'fileLocationUUID' | 'isFileLocationActive'>
>;

type EditRequestContent = Partial<
  Pick<FileDetailMetadata, 'fileName' | 'fileType' | 'fileUUID'>
> & {
  fileLocations: ReducedFileLocation[];
};

type FileEditProps = {
  filesOverview: FileOverviewMetadata[];
  onEditFilesComplete?: () => void;
  onPurgeFilesComplete?: () => void;
};

type FileToEdit = FileDetailMetadata & {
  dataIncompleteError?: unknown;
  isSelected?: boolean;
};

const FILE_EDIT_FORM_DEFAULT_PROPS = {
  onEditFilesComplete: undefined,
  onPurgeFilesComplete: undefined,
};

const FileEditForm = (
  {
    filesOverview,
    onEditFilesComplete,
    onPurgeFilesComplete,
  }: FileEditProps = FILE_EDIT_FORM_DEFAULT_PROPS as FileEditProps,
): JSX.Element => {
  const [editRequestContents, setEditRequestContents] = useState<
    EditRequestContent[]
  >([]);
  const [filesToEdit, setFilesToEdit] = useState<FileToEdit[]>([]);
  const [isLoadingFilesToEdit, setIsLoadingFilesToEdit] =
    useState<boolean>(false);
  const [isOpenPurgeConfirmDialog, setIsOpenConfirmPurgeDialog] =
    useState<boolean>(false);
  const [selectedFilesCount, setSelectedFilesCount] = useState<number>(0);

  const purgeButtonStyleOverride = {
    backgroundColor: RED,
    color: TEXT,

    '&:hover': { backgroundColor: RED },
  };

  const generateFileInfoChangeHandler =
    (fileIndex: number): FileInfoChangeHandler =>
    (inputValues, { fileLocationIndex } = {}) => {
      if (fileLocationIndex !== undefined) {
        editRequestContents[fileIndex].fileLocations[fileLocationIndex] = {
          ...editRequestContents[fileIndex].fileLocations[fileLocationIndex],
          ...inputValues,
        };
      } else {
        editRequestContents[fileIndex] = {
          ...editRequestContents[fileIndex],
          ...inputValues,
        };
      }
    };

  const editFiles: FormEventHandler<HTMLFormElement> = (event) => {
    event.preventDefault();

    setIsLoadingFilesToEdit(true);

    const editPromises = editRequestContents.reduce<Promise<AxiosResponse>[]>(
      (
        reducedEditPromises,
        { fileLocations, fileName, fileType, fileUUID },
      ) => {
        const editRequestContent: Partial<EditRequestContent> = {};

        if (fileName !== undefined) {
          editRequestContent.fileName = fileName;
        }

        if (fileType !== undefined) {
          editRequestContent.fileType = fileType;
        }

        const changedFileLocations = fileLocations.reduce<
          ReducedFileLocation[]
        >(
          (
            reducedFileLocations,
            { fileLocationUUID, isFileLocationActive },
          ) => {
            if (isFileLocationActive !== undefined) {
              reducedFileLocations.push({
                fileLocationUUID,
                isFileLocationActive,
              });
            }

            return reducedFileLocations;
          },
          [],
        );

        if (changedFileLocations.length > 0) {
          editRequestContent.fileLocations = changedFileLocations;
        }

        const stringEditFileRequestContent = JSON.stringify(editRequestContent);

        if (stringEditFileRequestContent !== '{}') {
          reducedEditPromises.push(
            mainAxiosInstance.put(
              `/file/${fileUUID}`,
              stringEditFileRequestContent,
              {
                headers: { 'Content-Type': 'application/json' },
              },
            ),
          );
        }

        return reducedEditPromises;
      },
      [],
    );

    Promise.all(editPromises)
      .then(() => {
        setIsLoadingFilesToEdit(false);
      })
      .then(onEditFilesComplete);
  };

  const purgeFiles: MouseEventHandler<HTMLButtonElement> = () => {
    setIsOpenConfirmPurgeDialog(false);
    setIsLoadingFilesToEdit(true);

    const purgePromises = filesToEdit
      .filter(({ isSelected }) => isSelected)
      .map(({ fileUUID }) => mainAxiosInstance.delete(`/file/${fileUUID}`));

    Promise.all(purgePromises)
      .then(() => {
        setIsLoadingFilesToEdit(false);
      })
      .then(onPurgeFilesComplete);
  };

  const cancelPurge: MouseEventHandler<HTMLButtonElement> = () => {
    setIsOpenConfirmPurgeDialog(false);
  };

  const confirmPurge: MouseEventHandler<HTMLButtonElement> = () => {
    // We need this local variable because setState functions are async; the
    // changes won't reflect until the next render cycle.
    // In this case, the user would have to click on the purge button twice to
    // trigger the confirmation dialog without using this local variable.
    const localSelectedFilesCount = filesToEdit.filter(
      ({ isSelected }) => isSelected,
    ).length;

    setSelectedFilesCount(localSelectedFilesCount);

    if (localSelectedFilesCount > 0) {
      setIsOpenConfirmPurgeDialog(true);
    }
  };

  useEffect(() => {
    setIsLoadingFilesToEdit(true);

    Promise.all(
      filesOverview.map(async (fileOverview: FileOverviewMetadata) => {
        const fileToEdit: FileToEdit = {
          ...fileOverview,
          fileLocations: [],
        };

        try {
          const data = await fetchJSON<string[][]>(
            `${API_BASE_URL}/file/${fileOverview.fileUUID}`,
          );

          fileToEdit.fileLocations = data.map(
            ([
              ,
              ,
              ,
              ,
              ,
              fileLocationUUID,
              fileLocationActive,
              anvilUUID,
              anvilName,
              anvilDescription,
            ]) => ({
              anvilDescription,
              anvilName,
              anvilUUID,
              fileLocationUUID,
              isFileLocationActive: parseInt(fileLocationActive, 10) === 1,
            }),
          );
        } catch (fetchError) {
          fileToEdit.dataIncompleteError = fetchError;
        }

        return fileToEdit;
      }),
    ).then((fetchedFilesDetail) => {
      setFilesToEdit(fetchedFilesDetail);

      const initialEditRequestContents: EditRequestContent[] = [];

      for (
        let fileIndex = 0;
        fileIndex < fetchedFilesDetail.length;
        fileIndex += 1
      ) {
        const fetchedFileDetail = fetchedFilesDetail[fileIndex];
        initialEditRequestContents.push({
          fileUUID: fetchedFileDetail.fileUUID,
          fileLocations: fetchedFileDetail.fileLocations.map(
            ({ fileLocationUUID }) => ({
              fileLocationUUID,
            }),
          ),
        });
      }

      setEditRequestContents(initialEditRequestContents);

      setIsLoadingFilesToEdit(false);
    });
  }, [filesOverview]);

  return (
    <>
      {isLoadingFilesToEdit ? (
        <Spinner />
      ) : (
        <form onSubmit={editFiles}>
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              '& > :not(:first-child)': { marginTop: '1em' },
            }}
          >
            {filesToEdit.map(
              ({ fileName, fileLocations, fileType, fileUUID }, fileIndex) => (
                <Box
                  key={`file-edit-${fileUUID}`}
                  sx={{
                    display: 'flex',
                    flexDirection: 'row',
                    '& > :last-child': {
                      flexGrow: 1,
                    },
                  }}
                >
                  <Box sx={{ marginTop: '.4em' }}>
                    <Checkbox
                      onChange={({ target: { checked } }) => {
                        filesToEdit[fileIndex].isSelected = checked;
                      }}
                      sx={{
                        color: GREY,

                        [`&.${checkboxClasses.checked}`]: {
                          color: TEXT,
                        },
                      }}
                    />
                  </Box>
                  <FileInfo
                    {...{ fileName, fileType, fileLocations }}
                    onChange={generateFileInfoChangeHandler(fileIndex)}
                  />
                </Box>
              ),
            )}
            {filesToEdit.length > 0 && (
              <Box
                sx={{
                  display: 'flex',
                  flexDirection: 'row',
                  justifyContent: 'flex-end',
                  '& > :not(:last-child)': {
                    marginRight: '.5em',
                  },
                }}
              >
                <ContainedButton
                  onClick={confirmPurge}
                  sx={purgeButtonStyleOverride}
                >
                  Purge
                </ContainedButton>
                <ContainedButton type="submit">Update</ContainedButton>
              </Box>
            )}
          </Box>
          <ConfirmDialog
            actionProceedText="Purge"
            contentText={`${selectedFilesCount} files will be removed from the system. You cannot undo this purge.`}
            dialogProps={{ open: isOpenPurgeConfirmDialog }}
            onCancel={cancelPurge}
            onProceed={purgeFiles}
            proceedButtonProps={{ sx: purgeButtonStyleOverride }}
            titleText={`Are you sure you want to purge ${selectedFilesCount} selected files? `}
          />
        </form>
      )}
    </>
  );
};

FileEditForm.defaultProps = FILE_EDIT_FORM_DEFAULT_PROPS;

export default FileEditForm;
