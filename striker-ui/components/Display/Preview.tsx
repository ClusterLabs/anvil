import { Dispatch, FC, SetStateAction, useEffect, useState } from 'react';
import { Box, IconButton as MUIIconButton } from '@mui/material';
import {
  DesktopWindows as DesktopWindowsIcon,
  PowerOffOutlined as PowerOffOutlinedIcon,
} from '@mui/icons-material';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import IconButton from '../IconButton';
import { Panel, PanelHeader } from '../Panels';
import { HeaderText } from '../Text';

type PreviewOptionalProps = {
  isShowControls?: boolean;
  setMode?: Dispatch<SetStateAction<boolean>> | null;
};

type PreviewProps = PreviewOptionalProps & {
  uuid: string;
  serverName: string | string[] | undefined;
};

const PREVIEW_DEFAULT_PROPS: Required<PreviewOptionalProps> = {
  isShowControls: true,
  setMode: null,
};

const Preview: FC<PreviewProps> = ({
  isShowControls = PREVIEW_DEFAULT_PROPS.isShowControls,
  serverName,
  setMode,
  uuid,
}) => {
  const [preview, setPreview] = useState<string>();

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/get_server_screenshot?server_uuid=${uuid}`,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
            },
          },
        );
        const { screenshot } = await res.json();
        setPreview(screenshot);
      } catch {
        setPreview('');
      }
    })();
  }, [uuid]);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text={`Server: ${serverName}`} />
      </PanelHeader>
      <Box
        sx={{
          display: 'flex',
          width: '100%',

          '& > :not(:last-child)': {
            marginRight: '1em',
          },
        }}
      >
        <Box>
          <MUIIconButton
            component="span"
            onClick={() => setMode?.call(null, false)}
            sx={{
              color: GREY,
              padding: 0,
            }}
          >
            {preview ? (
              <Box
                alt=""
                component="img"
                src={`data:image/png;base64,${preview}`}
                sx={{
                  height: '100%',
                  width: '100%',
                }}
              />
            ) : (
              <PowerOffOutlinedIcon
                sx={{
                  height: '100%',
                  padding: 0,
                  width: '100%',
                }}
              />
            )}
          </MUIIconButton>
        </Box>
        {isShowControls && (
          <Box>
            <IconButton onClick={() => setMode?.call(null, false)}>
              <DesktopWindowsIcon />
            </IconButton>
          </Box>
        )}
      </Box>
    </Panel>
  );
};

Preview.defaultProps = PREVIEW_DEFAULT_PROPS;

export default Preview;
