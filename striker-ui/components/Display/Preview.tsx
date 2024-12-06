import { PowerSettingsNewOutlined as PowerSettingsNewOutlinedIcon } from '@mui/icons-material';
import { Box, BoxProps, IconButton, IconButtonProps } from '@mui/material';
import { cloneElement, createElement, useMemo } from 'react';

import { GREY, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

import PreviewBox from './PreviewBox';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import { elapsed, last, now } from '../../lib/time';
import useFetch from '../../hooks/useFetch';

type ServerCore = Pick<APIServerOverview, 'name' | 'state' | 'uuid'>;

type PreviewOptionalProps = {
  href?: string;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  slotProps?: {
    button?: IconButtonProps;
    screenshot?: BoxProps;
    screenshotBox?: BoxProps;
  };
  slots?: {
    screenshotBox?: React.ReactElement<BoxProps>;
  };
};

type PreviewProps<Server extends ServerCore> = PreviewOptionalProps & {
  server: Server;
};

const Preview = <Server extends ServerCore>(
  ...[props]: Parameters<React.FC<PreviewProps<Server>>>
): ReturnType<React.FC<PreviewProps<Server>>> => {
  const { href, onClick: handleClickPreview, server, slotProps, slots } = props;

  const { data, loading: loadingPreview } = useFetch<APIServerDetailScreenshot>(
    `/server/${server.uuid}?ss=1`,
    {
      refreshInterval: 60000,
    },
  );

  const preview = data?.screenshot;
  const timestamp = data?.timestamp;

  const nao = now();

  const stale = useMemo<boolean>(() => {
    if (!timestamp) return false;

    return !last(timestamp, 300);
  }, [timestamp]);

  const content = useMemo(() => {
    const wrapper = slots?.screenshotBox || <PreviewBox />;
    const wrapperProps = { ...slotProps?.screenshotBox };

    if (loadingPreview) {
      return cloneElement(wrapper, wrapperProps, <Spinner mt={0} />);
    }

    if (server.state !== 'running') {
      return cloneElement(
        wrapper,
        wrapperProps,
        <PowerSettingsNewOutlinedIcon
          sx={{
            color: UNSELECTED,
            height: '100%',
            width: 'auto',
          }}
        />,
      );
    }

    let opacity = '1';
    let staleMsg: React.ReactNode;

    if (timestamp && stale) {
      opacity = '0.4';

      const { unit, value } = elapsed(nao - timestamp);

      staleMsg = (
        <BodyText position="absolute">
          Updated ~{value} {unit} ago
        </BodyText>
      );
    }

    return cloneElement(
      wrapper,
      wrapperProps,
      <Box
        alt={`Preview is temporarily unavailable, but the server is ${server.state}.`}
        component="img"
        src={`data:image;base64,${preview}`}
        sx={{
          color: GREY,
          height: '100%',
          opacity,
          width: 'auto',
        }}
        {...slotProps?.screenshot}
      />,
      staleMsg,
    );
  }, [
    loadingPreview,
    nao,
    preview,
    server.state,
    slotProps?.screenshot,
    slotProps?.screenshotBox,
    slots?.screenshotBox,
    stale,
    timestamp,
  ]);

  const button = useMemo(() => {
    const disabled = !preview;

    return createElement(
      IconButton,
      {
        disabled,
        href,
        onClick: handleClickPreview,
        sx: {
          padding: 0,
        },
        ...slotProps?.button,
      },
      content,
    );
  }, [content, handleClickPreview, href, preview, slotProps?.button]);

  return button;
};

export default Preview;
