import { PowerSettingsNewOutlined as PowerSettingsNewOutlinedIcon } from '@mui/icons-material';
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
import { InnerPanel, InnerPanelHeader, Panel, PanelHeader } from '../Panels';
import ServerMenu from '../ServerMenu';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import { elapsed, last, now } from '../../lib/time';

type PreviewOptionalProps = {
  externalPreview?: string;
  externalTimestamp?: number;
  headerEndAdornment?: ReactNode;
  hrefPreview?: string;
  isExternalLoading?: boolean;
  isExternalPreviewStale?: boolean;
  isFetchPreview?: boolean;
  isShowControls?: boolean;
  isUseInnerPanel?: boolean;
  onClickPreview?: MUIIconButtonProps['onClick'];
  serverName?: string;
  serverState?: string;
  slotProps?: {
    innerPanel?: InnerPanelProps;
    panel?: PanelProps;
  };
};

type PreviewProps = PreviewOptionalProps & {
  serverUUID: string;
};

const PREVIEW_DEFAULT_PROPS: Required<
  Omit<PreviewOptionalProps, 'hrefPreview' | 'onClickPreview'>
> &
  Pick<PreviewOptionalProps, 'hrefPreview' | 'onClickPreview'> = {
  externalPreview: '',
  externalTimestamp: 0,
  headerEndAdornment: null,
  hrefPreview: undefined,
  isExternalLoading: false,
  isExternalPreviewStale: false,
  isFetchPreview: true,
  isShowControls: true,
  isUseInnerPanel: false,
  onClickPreview: undefined,
  serverName: '',
  serverState: '',
  slotProps: {},
};

const PreviewPanel: FC<{
  isUseInnerPanel: boolean;
  slotProps: Exclude<PreviewProps['slotProps'], undefined>;
}> = ({ children, isUseInnerPanel, slotProps }) =>
  isUseInnerPanel ? (
    <InnerPanel {...slotProps.innerPanel}>{children}</InnerPanel>
  ) : (
    <Panel {...slotProps.panel}>{children}</Panel>
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
  hrefPreview,
  isExternalLoading = PREVIEW_DEFAULT_PROPS.isExternalLoading,
  isExternalPreviewStale = PREVIEW_DEFAULT_PROPS.isExternalPreviewStale,
  isFetchPreview = PREVIEW_DEFAULT_PROPS.isFetchPreview,
  isShowControls = PREVIEW_DEFAULT_PROPS.isShowControls,
  isUseInnerPanel = PREVIEW_DEFAULT_PROPS.isUseInnerPanel,
  onClickPreview: previewClickHandler,
  serverName = PREVIEW_DEFAULT_PROPS.serverName,
  serverState = PREVIEW_DEFAULT_PROPS.serverState,
  serverUUID,
  slotProps = PREVIEW_DEFAULT_PROPS.slotProps,
}) => {
  const [isPreviewLoading, setIsPreviewLoading] = useState<boolean>(true);
  const [isPreviewStale, setIsPreviewStale] = useState<boolean>(false);
  const [preview, setPreview] = useState<string>('');
  const [previewTimstamp, setPreviewTimestamp] = useState<number>(0);

  const nao = now();

  const previewButtonContent = useMemo(
    () =>
      serverState === 'running' ? (
        <>
          <Box
            alt={`Preview is temporarily unavailable, but the server is ${serverState}.`}
            component="img"
            src={`data:image;base64,${preview}`}
            sx={{
              height: 'auto',
              minHeight: preview ? undefined : '10em',
              opacity: isPreviewStale ? '0.4' : '1',
              padding: isUseInnerPanel ? '.2em' : 0,
              width: '100%',
            }}
          />
          {isPreviewStale &&
            ((sst: number) => {
              const { unit, value } = elapsed(nao - sst);

              return (
                <BodyText position="absolute">
                  Updated ~{value} {unit} ago
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
    [
      isPreviewStale,
      isUseInnerPanel,
      nao,
      preview,
      previewTimstamp,
      serverState,
    ],
  );

  const iconButton = useMemo(() => {
    if (isPreviewLoading) {
      return <Spinner mb="1em" mt="1em" />;
    }

    const disabled = !preview;
    const sx: MUIIconButtonProps['sx'] = {
      borderRadius: BORDER_RADIUS,
      color: GREY,
      padding: 0,
    };

    if (hrefPreview) {
      return (
        <MUIIconButton disabled={disabled} href={hrefPreview} sx={sx}>
          {previewButtonContent}
        </MUIIconButton>
      );
    }

    return (
      <MUIIconButton
        component="span"
        disabled={disabled}
        onClick={previewClickHandler}
        sx={sx}
      >
        {previewButtonContent}
      </MUIIconButton>
    );
  }, [
    hrefPreview,
    isPreviewLoading,
    preview,
    previewButtonContent,
    previewClickHandler,
  ]);

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
    <PreviewPanel isUseInnerPanel={isUseInnerPanel} slotProps={slotProps}>
      <PreviewPanelHeader isUseInnerPanel={isUseInnerPanel} text={serverName}>
        {headerEndAdornment}
        {isShowControls && (
          <ServerMenu
            iconButtonProps={{ size: isUseInnerPanel ? 'small' : undefined }}
            serverName={serverName}
            serverState={serverState}
            serverUuid={serverUUID}
          />
        )}
      </PreviewPanelHeader>
      <FlexBox row sx={{ '& > :first-child': { flexGrow: 1 } }}>
        {/* Box wrapper below is required to keep external preview size sane. */}
        <Box textAlign="center">{iconButton}</Box>
      </FlexBox>
    </PreviewPanel>
  );
};

Preview.defaultProps = PREVIEW_DEFAULT_PROPS;

export default Preview;
