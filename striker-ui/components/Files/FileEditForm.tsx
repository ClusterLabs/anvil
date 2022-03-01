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

type FileEditProps = {
  filesOverview: FileOverviewMetadata[];
};

type FileToEdit = FileDetailMetadata & {
  dataIncompleteError?: unknown;
  isSelected?: boolean;
};

const FileEditForm = ({ filesOverview }: FileEditProps): JSX.Element => {
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
      if (fileLocationIndex) {
        filesToEdit[fileIndex].fileLocations[fileLocationIndex] = {
          ...filesToEdit[fileIndex].fileLocations[fileLocationIndex],
          ...inputValues,
        };
      } else {
        filesToEdit[fileIndex] = {
          ...filesToEdit[fileIndex],
          ...inputValues,
        };
      }
    };

  const editFiles: FormEventHandler<HTMLFormElement> = (event) => {
    event.preventDefault();

    filesToEdit.forEach(({ fileLocations, fileName, fileType, fileUUID }) => {
      mainAxiosInstance.put(
        `/files/${fileUUID}`,
        JSON.stringify({
          fileName,
          fileType,
          fileLocations: fileLocations.map(
            ({ fileLocationUUID, isFileLocationActive }) => ({
              fileLocationUUID,
              isFileLocationActive,
            }),
          ),
        }),
        {
          headers: { 'Content-Type': 'application/json' },
        },
      );
    });
  };

  const purgeFiles: MouseEventHandler<HTMLButtonElement> = () => {
    setIsOpenConfirmPurgeDialog(false);

    filesToEdit
      .filter(({ isSelected }) => isSelected)
      .forEach(({ fileUUID }) => {
        mainAxiosInstance.delete(`/files/${fileUUID}`);
      });
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
            `${API_BASE_URL}/files/${fileOverview.fileUUID}`,
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

export default FileEditForm;
