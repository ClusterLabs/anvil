import {
  FormEventHandler,
  MouseEventHandler,
  useEffect,
  useState,
} from 'react';
import { Box, Checkbox, checkboxClasses } from '@mui/material';

import { GREY, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';

import FileInfo from './FileInfo';
import fetchJSON from '../../lib/fetchers/fetchJSON';
import mainAxiosInstance from '../../lib/singletons/mainAxiosInstance';
import StyledContainedButton from './StyledContainedButton';
import Spinner from '../Spinner';

type FileEditProps = {
  filesOverview: FileOverviewMetadata[];
};

type FileToEdit = FileDetailMetadata & {
  dataIncompleteError?: unknown;
  isSelected?: boolean;
};

const FileEditForm = ({ filesOverview }: FileEditProps): JSX.Element => {
  const [filesToEdit, setFilesToEdit] = useState<FileToEdit[]>([]);
  const [isLoadingFilesToEdit, setIsLoadingFilesToEdit] = useState<boolean>(
    false,
  );

  const generateFileInfoChangeHandler = (
    fileIndex: number,
  ): FileInfoChangeHandler => (inputValues, { fileLocationIndex } = {}) => {
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
    filesToEdit
      .filter(({ isSelected }) => isSelected)
      .forEach(({ fileUUID }) => {
        mainAxiosInstance.delete(`/files/${fileUUID}`);
      });
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
            `${process.env.NEXT_PUBLIC_API_URL?.replace(
              '/cgi-bin',
              '/api',
            )}/files/${fileOverview.fileUUID}`,
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
                <StyledContainedButton
                  onClick={purgeFiles}
                  sx={{
                    backgroundColor: RED,
                    color: TEXT,
                    '&:hover': { backgroundColor: RED },
                  }}
                >
                  Purge
                </StyledContainedButton>
                <StyledContainedButton type="submit">
                  Update
                </StyledContainedButton>
              </Box>
            )}
          </Box>
        </form>
      )}
    </>
  );
};

export default FileEditForm;
