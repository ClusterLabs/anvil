import {
  DesktopWindows as DesktopWindowsIcon,
  PowerSettingsNewOutlined as PowerSettingsNewOutlinedIcon,
} from '@mui/icons-material';
import {
  Box,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
} from '@mui/material';
import { FC, ReactNode, useEffect, useMemo, useState } from 'react';

import {
  BORDER_RADIUS,
  GREY,
  UNSELECTED,
} from '../../lib/consts/DEFAULT_THEME';

import api from '../../lib/api';
import FlexBox from '../FlexBox';
import IconButton, { IconButtonProps } from '../IconButton';
import { InnerPanel, InnerPanelHeader, Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import { elapsed, last, now } from '../../lib/time';

type PreviewOptionalProps = {
  externalPreview?: string;
  externalTimestamp?: number;
  headerEndAdornment?: ReactNode;
  isExternalLoading?: boolean;
  isExternalPreviewStale?: boolean;
  isFetchPreview?: boolean;
  isShowControls?: boolean;
  isUseInnerPanel?: boolean;
  onClickConnectButton?: IconButtonProps['onClick'];
  onClickPreview?: MUIIconButtonProps['onClick'];
  serverName?: string;
  serverState?: string;
};

type PreviewProps = PreviewOptionalProps & {
  serverUUID: string;
};

const PREVIEW_DEFAULT_PROPS: Required<
  Omit<PreviewOptionalProps, 'onClickConnectButton' | 'onClickPreview'>
> &
  Pick<PreviewOptionalProps, 'onClickConnectButton' | 'onClickPreview'> = {
  externalPreview: '',
  externalTimestamp: 0,
  headerEndAdornment: null,
  isExternalLoading: false,
  isExternalPreviewStale: false,
  isFetchPreview: true,
  isShowControls: true,
  isUseInnerPanel: false,
  onClickConnectButton: undefined,
  onClickPreview: undefined,
  serverName: '',
  serverState: '',
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
  externalTimestamp = PREVIEW_DEFAULT_PROPS.externalTimestamp,
  headerEndAdornment,
  isExternalLoading = PREVIEW_DEFAULT_PROPS.isExternalLoading,
  isExternalPreviewStale = PREVIEW_DEFAULT_PROPS.isExternalPreviewStale,
  isFetchPreview = PREVIEW_DEFAULT_PROPS.isFetchPreview,
  isShowControls = PREVIEW_DEFAULT_PROPS.isShowControls,
  isUseInnerPanel = PREVIEW_DEFAULT_PROPS.isUseInnerPanel,
  onClickPreview: previewClickHandler,
  serverName,
  serverState = PREVIEW_DEFAULT_PROPS.serverState,
  serverUUID,
  onClickConnectButton: connectButtonClickHandle = previewClickHandler,
}) => {
  const [isPreviewLoading, setIsPreviewLoading] = useState<boolean>(true);
  const [isPreviewStale, setIsPreviewStale] = useState<boolean>(false);
  const [preview, setPreview] = useState<string>('');
  const [previewTimstamp, setPreviewTimestamp] = useState<number>(0);

  const previewButtonContent = useMemo(
    () =>
      serverState === 'running' ? (
        <>
          <Box
            alt=""
            component="img"
            src={`data:image;base64,${preview}`}
            sx={{
              height: '100%',
              opacity: isPreviewStale ? '0.4' : '1',
              padding: isUseInnerPanel ? '.2em' : 0,
              width: '100%',
            }}
          />
          {isPreviewStale &&
            ((sst: number) => {
              const { unit, value } = elapsed(now() - sst);

              return (
                <BodyText position="absolute">
                  Lost ~{value} {unit} ago
                </BodyText>
              );
            })(previewTimstamp)}
        </>
      ) : (
        <PowerSettingsNewOutlinedIcon
          sx={{
            color: UNSELECTED,
            height: '80%',
            width: '80%',
          }}
        />
      ),
    [isPreviewStale, isUseInnerPanel, preview, previewTimstamp, serverState],
  );

  useEffect(() => {
    if (isFetchPreview) {
      (async () => {
        try {
          const { data } = await api.get<{
            screenshot: string;
            timestamp: number;
          }>(`/server/${serverUUID}?ss=1`);

          const { screenshot, timestamp } = data;

          setPreview(screenshot);
          setPreviewTimestamp(timestamp);
          setIsPreviewStale(!last(timestamp, 300));
        } catch {
          setIsPreviewStale(true);
        } finally {
          setIsPreviewLoading(false);
        }
      })();
    } else if (!isExternalLoading) {
      setPreview(externalPreview);
      setPreviewTimestamp(externalTimestamp);
      setIsPreviewStale(isExternalPreviewStale);
      setIsPreviewLoading(false);
    }
  }, [
    externalPreview,
    externalTimestamp,
    isExternalLoading,
    isExternalPreviewStale,
    isFetchPreview,
    serverUUID,
  ]);

  return (
    <PreviewPanel isUseInnerPanel={isUseInnerPanel}>
      <PreviewPanelHeader isUseInnerPanel={isUseInnerPanel} text={serverName}>
        {headerEndAdornment}
      </PreviewPanelHeader>
      <FlexBox row sx={{ '& > :first-child': { flexGrow: 1 } }}>
        {/* Box wrapper below is required to keep external preview size sane. */}
        <Box textAlign="center">
          {isPreviewLoading ? (
            <Spinner mt="1em" mb="1em" />
          ) : (
            <MUIIconButton
              component="span"
              disabled={!preview}
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
        {isShowControls && preview && (
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
