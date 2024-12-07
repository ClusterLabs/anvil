import { PowerSettingsNewOutlined as PowerSettingsNewOutlinedIcon } from '@mui/icons-material';
import {
  Box,
  BoxProps,
  circularProgressClasses,
  IconButton,
  IconButtonProps,
} from '@mui/material';
import { cloneElement, createElement, useMemo } from 'react';

import { GREY, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

import PieProgress from '../PieProgress';
import PreviewBox from './PreviewBox';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import { elapsed, last, now } from '../../lib/time';
import useFetch from '../../hooks/useFetch';

type ServerCore = Pick<APIServerOverview, 'jobs' | 'name' | 'state' | 'uuid'>;

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
  const {
    href: previewHref,
    onClick: handleClickPreview,
    server,
    slotProps,
    slots,
  } = props;

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

  const wrapper = useMemo(
    () => slots?.screenshotBox ?? <PreviewBox />,
    [slots?.screenshotBox],
  );

  const wrapperProps = useMemo(
    () => ({ ...slotProps?.screenshotBox }),
    [slotProps?.screenshotBox],
  );

  const content = useMemo(() => {
    if (server.jobs) {
      return cloneElement(
        wrapper,
        wrapperProps,
        <>
          <BodyText>Provisioning...</BodyText>
          {Object.values(server.jobs).map((job, index) => {
            const { peer, progress, uuid } = job;

            const size = `calc(7em - ${1.5 * index}em)`;

            return (
              <PieProgress
                key={`${uuid}-progress`}
                slotProps={{
                  box: {
                    sx: {
                      position: 'absolute',
                    },
                  },
                  pie: {
                    size,
                    sx: {
                      opacity: peer ? 0.6 : undefined,

                      [`& .${circularProgressClasses.circle}`]: {
                        strokeLinecap: 'round',
                      },
                    },
                    thickness: 3,
                  },
                  underline: {
                    thickness: 0,
                  },
                }}
                value={progress}
              />
            );
          })}
        </>,
      );
    }

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
    server.jobs,
    server.state,
    slotProps?.screenshot,
    stale,
    timestamp,
    wrapper,
    wrapperProps,
  ]);

  const button = useMemo(() => {
    const disabled = !preview;

    return createElement(
      IconButton,
      {
        disabled,
        href: previewHref,
        onClick: handleClickPreview,
        sx: {
          padding: 0,
        },
        ...slotProps?.button,
      },
      content,
    );
  }, [content, handleClickPreview, preview, previewHref, slotProps?.button]);

  return button;
};

export default Preview;
