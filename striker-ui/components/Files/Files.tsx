import { useEffect, useState } from 'react';
import { Box, IconButton } from '@mui/material';
import { Add as AddIcon, Edit as EditIcon } from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import EventEmitter from 'events';

import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';

import { Panel } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import FileList from './FileList';
import FileUploadForm from './FileUploadForm';
import FileEditForm from './FileEditForm';
import fetchJSON from '../../lib/fetchers/fetchJSON';

const PREFIX = 'Files';

const classes = {
  addFileButton: `${PREFIX}-addFileButton`,
  addFileInput: `${PREFIX}-addFileInput`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.addFileButton}`]: ICON_BUTTON_STYLE,

  [`& .${classes.addFileInput}`]: {
    display: 'none',
  },
}));

const StyledIconButton = styled(IconButton)(ICON_BUTTON_STYLE);

const Files = (): JSX.Element => {
  const [rawFilesOverview, setRawFilesOverview] = useState<string[][]>([]);
  const [
    isLoadingRawFilesOverview,
    setIsLoadingRawFilesOverview,
  ] = useState<boolean>(false);
  const [isEditMode, setIsEditMode] = useState<boolean>(false);

  const openFilePickerEventEmitter: EventEmitter = new EventEmitter();

  const onAddFileButtonClick = () => {
    openFilePickerEventEmitter.emit('open');
  };

  const onEditFileButtonClick = () => {
    setIsEditMode(!isEditMode);
  };

  const buildFileList = (): JSX.Element => {
    let elements: JSX.Element;
    if (isLoadingRawFilesOverview) {
      elements = <Spinner />;
    } else {
      const filesOverview: FileOverviewMetadata[] = rawFilesOverview.map(
        ([fileUUID, fileName, fileSizeInBytes, fileType, fileChecksum]) => {
          return {
            fileChecksum,
            fileName,
            fileSizeInBytes: parseInt(fileSizeInBytes, 10),
            fileType: fileType as FileType,
            fileUUID,
          };
        },
      );

      elements = isEditMode ? (
        <FileEditForm filesOverview={filesOverview} />
      ) : (
        <FileList filesOverview={filesOverview} />
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
      <StyledDiv>
        <Box style={{ display: 'flex', width: '100%' }}>
          <Box style={{ flexGrow: 1 }}>
            <HeaderText text="Files" />
          </Box>
          <Box>
            <StyledIconButton onClick={onAddFileButtonClick}>
              <AddIcon />
            </StyledIconButton>
          </Box>
          <Box>
            <StyledIconButton onClick={onEditFileButtonClick}>
              <EditIcon />
            </StyledIconButton>
          </Box>
        </Box>
        <FileUploadForm
          onFileUploadComplete={() => {
            fetchRawFilesOverview();
          }}
          openFilePickerEventEmitter={openFilePickerEventEmitter}
        />
        {buildFileList()}
      </StyledDiv>
    </Panel>
  );
};

export default Files;
