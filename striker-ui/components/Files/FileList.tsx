import { Box, Divider, List, ListItem } from '@mui/material';
import * as prettyBytes from 'pretty-bytes';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';
import { UPLOAD_FILE_TYPES } from '../../lib/consts/UPLOAD_FILE_TYPES';

import { BodyText } from '../Text';

type FileListProps = {
  filesOverview: FileOverviewMetadata[];
};

const FileList = ({ filesOverview }: FileListProps): JSX.Element => {
  return (
    <List>
      {filesOverview.map(
        ({ fileChecksum, fileName, fileSizeInBytes, fileType, fileUUID }) => {
          const fileSize: string = prettyBytes.default(fileSizeInBytes, {
            binary: true,
          });

          return (
            <ListItem key={fileUUID} sx={{ padding: '.6em 0' }}>
              <Box
                sx={{
                  display: 'flex',
                  flexDirection: { xs: 'column', md: 'row' },
                  width: '100%',
                }}
              >
                <Box sx={{ flexGrow: 1 }}>
                  <Box
                    sx={{
                      display: 'flex',
                      flexDirection: 'row',
                    }}
                  >
                    <BodyText
                      sx={{
                        fontFamily: 'Source Code Pro',
                        fontWeight: 400,
                      }}
                      text={fileName}
                    />
                    <Divider
                      flexItem
                      orientation="vertical"
                      sx={{
                        backgroundColor: DIVIDER,
                        marginLeft: '.5em',
                        marginRight: '.5em',
                      }}
                    />
                    <BodyText
                      text={UPLOAD_FILE_TYPES.get(fileType)?.[1] ?? ''}
                    />
                  </Box>
                  <BodyText text={fileSize} />
                </Box>
                <Box
                  sx={{
                    alignItems: 'center',
                    display: 'flex',
                    flexDirection: 'row',
                  }}
                >
                  <BodyText
                    sx={{
                      fontFamily: 'Source Code Pro',
                      fontWeight: 400,
                    }}
                    text={fileChecksum}
                  />
                </Box>
              </Box>
            </ListItem>
          );
        },
      )}
    </List>
  );
};

export default FileList;
