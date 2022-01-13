import { Box, Divider, List, ListItem } from '@mui/material';
import * as prettyBytes from 'pretty-bytes';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import { BodyText } from '../Text';

const FileList = ({ list = [] }: { list: string[][] }): JSX.Element => {
  return (
    <List>
      {list.map((file) => {
        const fileUUID: string = file[0];
        const fileName: string = file[1];
        const fileSize: string = prettyBytes.default(parseInt(file[2], 10), {
          binary: true,
        });
        const fileType: string = file[3];
        const fileChecksum: string = file[4];

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
      })}
    </List>
  );
};

export default FileList;
