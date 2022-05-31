import { Dispatch, FC, SetStateAction, useEffect, useState } from 'react';
import { Box, IconButton as MUIIconButton } from '@mui/material';
import {
  DesktopWindows as DesktopWindowsIcon,
  PowerOffOutlined as PowerOffOutlinedIcon,
} from '@mui/icons-material';

import { BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

import IconButton from '../IconButton';
import { InnerPanel, InnerPanelHeader, Panel, PanelHeader } from '../Panels';
import { BodyText, HeaderText } from '../Text';

type PreviewOptionalProps = {
  isShowControls?: boolean;
  isUseInnerPanel?: boolean;
  setMode?: Dispatch<SetStateAction<boolean>> | null;
};

type PreviewProps = PreviewOptionalProps & {
  uuid: string;
  serverName: string | string[] | undefined;
};

const PREVIEW_DEFAULT_PROPS: Required<PreviewOptionalProps> = {
  isShowControls: true,
  isUseInnerPanel: false,
  setMode: null,
};

const PreviewPanel: FC<{ isUseInnerPanel: boolean }> = ({
  children,
  isUseInnerPanel,
}) =>
  isUseInnerPanel ? (
    <InnerPanel>{children}</InnerPanel>
  ) : (
    <Panel>{children}</Panel>
  );

const PreviewPanelHeader: FC<{ isUseInnerPanel: boolean; text: string }> = ({
  children,
  isUseInnerPanel,
  text,
}) =>
  isUseInnerPanel ? (
    <InnerPanelHeader>
      <BodyText text={text} />
      {children}
    </InnerPanelHeader>
  ) : (
    <PanelHeader>
      <HeaderText text={text} />
      {children}
    </PanelHeader>
  );

const Preview: FC<PreviewProps> = ({
  isShowControls = PREVIEW_DEFAULT_PROPS.isShowControls,
  isUseInnerPanel = PREVIEW_DEFAULT_PROPS.isUseInnerPanel,
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
    <PreviewPanel isUseInnerPanel={isUseInnerPanel}>
      <PreviewPanelHeader
        isUseInnerPanel={isUseInnerPanel}
        text={`Server: ${serverName}`}
      />
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
              borderRadius: BORDER_RADIUS,
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
    </PreviewPanel>
  );
};

Preview.defaultProps = PREVIEW_DEFAULT_PROPS;

export default Preview;
