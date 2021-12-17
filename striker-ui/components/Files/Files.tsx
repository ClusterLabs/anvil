import { useRef } from 'react';
import { Box, IconButton, Input, InputLabel } from '@material-ui/core';
import AddIcon from '@material-ui/icons/Add';
import { makeStyles } from '@material-ui/core/styles';

import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';

import { Panel } from '../Panels';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';

const useStyles = makeStyles(() => ({
  addFileButton: ICON_BUTTON_STYLE,
  addFileInput: {
    display: 'none',
  },
}));

const Files = (): JSX.Element => {
  const classes = useStyles();
  const addFileInputRef = useRef<HTMLInputElement>();

  const { data, isLoading } = PeriodicFetch(
    `${process.env.NEXT_PUBLIC_API_URL?.replace('/cgi-bin', '/api')}/files`,
  );

  // Let the icon button trigger the invisible input element.
  const onAddFileButtonClick = () => {
    addFileInputRef.current?.click();
  };

  return (
    <Panel>
      <Box style={{ display: 'flex', width: '100%' }}>
        <Box style={{ flexGrow: 1 }}>
          <HeaderText text="Files" />
        </Box>
        <Box>
          <form encType="multipart/form-data">
            <InputLabel htmlFor="add-file-input">
              <Input
                className={classes.addFileInput}
                id="add-file-input"
                ref={addFileInputRef}
                type="file"
              />
              <IconButton
                className={classes.addFileButton}
                onClick={onAddFileButtonClick}
              >
                <AddIcon />
              </IconButton>
            </InputLabel>
          </form>
        </Box>
      </Box>
      {isLoading ? (
        <Spinner />
      ) : (
        <Box>
          <span>{data}</span>
        </Box>
      )}
    </Panel>
  );
};

export default Files;
