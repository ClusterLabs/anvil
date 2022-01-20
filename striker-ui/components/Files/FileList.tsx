import { Box, Divider, List, ListItem } from '@mui/material';
import * as prettyBytes from 'pretty-bytes';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

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
            <ListItem button key={fileUUID}>
              <Box
                sx={{
                  display: 'flex',
                  flexDirection: 'row',
                  width: '100%',
                }}
              >
                <Box sx={{ p: 1, flexGrow: 1 }}>
                  <Box
                    sx={{
                      display: 'flex',
                      flexDirection: 'row',
                    }}
                  >
                    <BodyText text={fileName} />
                    <Divider
                      flexItem
                      orientation="vertical"
                      sx={{
                        backgroundColor: DIVIDER,
                        marginLeft: '.5em',
                        marginRight: '.5em',
                      }}
                    />
                    <BodyText text={fileType} />
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
                  <BodyText text={fileChecksum} />
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
