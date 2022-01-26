import { useEffect, useState } from 'react';
import { Box, IconButton } from '@mui/material';
import {
  Add as AddIcon,
  Check as CheckIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import EventEmitter from 'events';

import { BLUE } from '../../lib/consts/DEFAULT_THEME';
import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';

import { Panel } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import FileList from './FileList';
import FileUploadForm from './FileUploadForm';
import FileEditForm from './FileEditForm';

import fetchJSON from '../../lib/fetchers/fetchJSON';

const StyledIconButton = styled(IconButton)(ICON_BUTTON_STYLE);

const Files = (): JSX.Element => {
  const [rawFilesOverview, setRawFilesOverview] = useState<string[][]>([]);
  const [
    isLoadingRawFilesOverview,
    setIsLoadingRawFilesOverview,
  ] = useState<boolean>(false);
  const [isEditMode, setIsEditMode] = useState<boolean>(false);

  const fileUploadFormEventEmitter: EventEmitter = new EventEmitter();

  const onAddFileButtonClick = () => {
    fileUploadFormEventEmitter.emit('openFilePicker');
  };

  const onEditFileButtonClick = () => {
    fileUploadFormEventEmitter.emit('clearSelectedFiles');

    setIsEditMode(!isEditMode);
  };

  const buildFileList = (): JSX.Element => {
    let elements: JSX.Element;
    if (isLoadingRawFilesOverview) {
      elements = <Spinner />;
    } else {
      const filesOverview: FileOverviewMetadata[] = rawFilesOverview.map(
        ([fileUUID, fileName, fileSizeInBytes, fileType, fileChecksum]) => ({
          fileChecksum,
          fileName,
          fileSizeInBytes: parseInt(fileSizeInBytes, 10),
          fileType: fileType as FileType,
          fileUUID,
        }),
      );

      elements = isEditMode ? (
        <FileEditForm {...{ filesOverview }} />
      ) : (
        <FileList {...{ filesOverview }} />
      );
    }

    return elements;
  };

  const fetchRawFilesOverview = async () => {
    setIsLoadingRawFilesOverview(true);

    const data = await fetchJSON<string[][]>(
      `${process.env.NEXT_PUBLIC_API_URL?.replace('/cgi-bin', '/api')}/files`,
    );

    setRawFilesOverview(data);
    setIsLoadingRawFilesOverview(false);
  };

  useEffect(() => {
    if (!isEditMode) {
      fetchRawFilesOverview();
    }
  }, [isEditMode]);

  return (
    <Panel>
      <Box
        sx={{
          alignItems: 'center',
          display: 'flex',
          flexDirection: 'row',
          marginBottom: '1em',
          width: '100%',
          '& > :first-child': { flexGrow: 1 },
          '& > :not(:first-child, :last-child)': {
            marginRight: '.3em',
          },
        }}
      >
        <HeaderText text="Files" />
        {!isEditMode && (
          <StyledIconButton onClick={onAddFileButtonClick}>
            <AddIcon />
          </StyledIconButton>
        )}
        <StyledIconButton onClick={onEditFileButtonClick}>
          {isEditMode ? <CheckIcon sx={{ color: BLUE }} /> : <EditIcon />}
        </StyledIconButton>
      </Box>
      <FileUploadForm
        {...{ eventEmitter: fileUploadFormEventEmitter }}
        onFileUploadComplete={() => {
          fetchRawFilesOverview();
        }}
      />
      {buildFileList()}
    </Panel>
  );
};

export default Files;
