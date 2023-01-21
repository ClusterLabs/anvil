import {
  DesktopWindows as DesktopWindowsIcon,
  PowerOffOutlined as PowerOffOutlinedIcon,
} from '@mui/icons-material';
import {
  Box,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
} from '@mui/material';
import { FC, ReactNode, useEffect, useMemo, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

import FlexBox from '../FlexBox';
import IconButton, { IconButtonProps } from '../IconButton';
import { InnerPanel, InnerPanelHeader, Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';

type PreviewOptionalProps = {
  externalPreview?: string;
  headerEndAdornment?: ReactNode;
  isExternalPreviewStale?: boolean;
  isFetchPreview?: boolean;
  isShowControls?: boolean;
  isUseInnerPanel?: boolean;
  onClickConnectButton?: IconButtonProps['onClick'];
  onClickPreview?: MUIIconButtonProps['onClick'];
  serverName?: string;
};

type PreviewProps = PreviewOptionalProps & {
  serverUUID: string;
};

const PREVIEW_DEFAULT_PROPS: Required<
  Omit<PreviewOptionalProps, 'onClickConnectButton' | 'onClickPreview'>
> &
  Pick<PreviewOptionalProps, 'onClickConnectButton' | 'onClickPreview'> = {
  externalPreview: '',
  headerEndAdornment: null,
  isExternalPreviewStale: false,
  isFetchPreview: true,
  isShowControls: true,
  isUseInnerPanel: false,
  onClickConnectButton: undefined,
  onClickPreview: undefined,
  serverName: '',
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

const PreviewPanelHeader: FC<{
  isUseInnerPanel: boolean;
  text: string | undefined;
}> = ({ children, isUseInnerPanel, text }) =>
  isUseInnerPanel ? (
    <InnerPanelHeader>
      {text ? <BodyText text={text} /> : <></>}
      {children}
    </InnerPanelHeader>
  ) : (
    <PanelHeader>
      {text ? <HeaderText text={text} /> : <></>}
      {children}
    </PanelHeader>
  );

const Preview: FC<PreviewProps> = ({
  externalPreview = PREVIEW_DEFAULT_PROPS.externalPreview,
  headerEndAdornment,
  isExternalPreviewStale = PREVIEW_DEFAULT_PROPS.isExternalPreviewStale,
  isFetchPreview = PREVIEW_DEFAULT_PROPS.isFetchPreview,
  isShowControls = PREVIEW_DEFAULT_PROPS.isShowControls,
  isUseInnerPanel = PREVIEW_DEFAULT_PROPS.isUseInnerPanel,
  onClickPreview: previewClickHandler,
  serverName,
  serverUUID,
  onClickConnectButton: connectButtonClickHandle = previewClickHandler,
}) => {
  const [isPreviewLoading, setIsPreviewLoading] = useState<boolean>(true);
  const [isPreviewStale, setIsPreviewStale] = useState<boolean>(false);
  const [preview, setPreview] = useState<string>('');

  const previewButtonContent = useMemo(
    () =>
      preview ? (
        <Box
          alt=""
          component="img"
          src={`data:image/png;base64,${preview}`}
          sx={{
            height: '100%',
            opacity: isPreviewStale ? '0.4' : '1',
            padding: isUseInnerPanel ? '.2em' : 0,
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
      ),
    [isPreviewStale, isUseInnerPanel, preview],
  );

  useEffect(() => {
    if (isFetchPreview) {
      (async () => {
        try {
          const response = await fetch(
            `${API_BASE_URL}/server/${serverUUID}?ss`,
            {
              method: 'GET',
              headers: {
                'Content-Type': 'application/json',
              },
            },
          );
          const { screenshot: fetchedScreenshot } = await response.json();

          setPreview(fetchedScreenshot);
          setIsPreviewStale(false);
        } catch {
          setIsPreviewStale(true);
        } finally {
          setIsPreviewLoading(false);
        }
      })();
    } else if (externalPreview) {
      setPreview(externalPreview);
      setIsPreviewStale(isExternalPreviewStale);
      setIsPreviewLoading(false);
    }
  }, [externalPreview, isExternalPreviewStale, isFetchPreview, serverUUID]);

  return (
    <PreviewPanel isUseInnerPanel={isUseInnerPanel}>
      <PreviewPanelHeader isUseInnerPanel={isUseInnerPanel} text={serverName}>
        {headerEndAdornment}
      </PreviewPanelHeader>
      <FlexBox row sx={{ '& > :first-child': { flexGrow: 1 } }}>
        {/* Box wrapper below is required to keep external preview size sane. */}
        <Box>
          {isPreviewLoading ? (
            <Spinner mt="1em" mb="1em" />
          ) : (
            <MUIIconButton
              component="span"
              onClick={previewClickHandler}
              sx={{
                borderRadius: BORDER_RADIUS,
                color: GREY,
                padding: 0,
              }}
            >
              {previewButtonContent}
            </MUIIconButton>
          )}
        </Box>
        {isShowControls && (
          <FlexBox>
            <IconButton onClick={connectButtonClickHandle}>
              <DesktopWindowsIcon />
            </IconButton>
          </FlexBox>
        )}
      </FlexBox>
    </PreviewPanel>
  );
};

Preview.defaultProps = PREVIEW_DEFAULT_PROPS;

export default Preview;
