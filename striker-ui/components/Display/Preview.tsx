import MuiPowerSettingsNewOutlinedIcon from '@mui/icons-material/PowerSettingsNewOutlined';
import MuiBox, { BoxProps as MuiBoxProps } from '@mui/material/Box';
import muiCircularProgressClasses from '@mui/material/CircularProgress/circularProgressClasses';
import MuiIconButton, {
  IconButtonProps as MuiIconButtonProps,
} from '@mui/material/IconButton';
import { LinkProps as MuiLinkProps } from '@mui/material/Link';
import capitalize from 'lodash/capitalize';
import merge from 'lodash/merge';
import { cloneElement, createElement, useMemo } from 'react';

import { GREY, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';
import SERVER from '../../lib/consts/SERVER';

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
    button?: MuiIconButtonProps;
    screenshot?: MuiBoxProps;
    screenshotBox?: MuiBoxProps;
  };
  slots?: {
    screenshotBox?: React.ReactElement<MuiBoxProps>;
  };
};

type PreviewProps<Server extends ServerCore> = PreviewOptionalProps & {
  server: Server;
};

const Preview = <Server extends ServerCore>(
  ...[props]: Parameters<React.FC<PreviewProps<Server>>>
): ReturnType<React.FC<PreviewProps<Server>>> => {
  const { onClick: handleClickPreview, server, slotProps, slots } = props;

  const { href: previewHref = `/server?name=${server.name}&view=vnc` } = props;

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

  const blocking = useMemo<boolean>(
    () => SERVER.states.blocking.includes(server.state),
    [server.state],
  );

  const content = useMemo(() => {
    if (blocking) {
      if (!server.jobs) {
        return undefined;
      }

      return cloneElement(
        wrapper,
        wrapperProps,
        <>
          <BodyText>{capitalize(server.state)}...</BodyText>
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

                      [`& .${muiCircularProgressClasses.circle}`]: {
                        strokeLinecap: 'round',
                      },
                    },
                    thickness: 3,
                  },
                  underline: {
                    thickness: progress ? 0 : 1,
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
        <MuiPowerSettingsNewOutlinedIcon
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

    let imgProps = slotProps?.screenshot;
    let imgSx;

    if (imgProps) {
      ({ sx: imgSx, ...imgProps } = imgProps);
    }

    return cloneElement(
      wrapper,
      wrapperProps,
      <MuiBox
        alt={`${capitalize(server.state)}. Preview unavailable`}
        component="img"
        src={`data:image;base64,${preview}`}
        sx={merge(
          {
            color: GREY,
            fontFamily: 'Roboto Condensed',
            height: preview ? '100%' : 'auto',
            opacity,
            width: 'auto',
          },
          imgSx,
        )}
        {...imgProps}
      />,
      staleMsg,
    );
  }, [
    blocking,
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
    const disabled = blocking;

    let buttonProps = slotProps?.button;
    let buttonSx;

    if (buttonProps) {
      ({ sx: buttonSx, ...buttonProps } = buttonProps);
    }

    return createElement<MuiIconButtonProps & Pick<MuiLinkProps, 'href'>>(
      MuiIconButton,
      {
        disabled,
        href: previewHref,
        onClick: handleClickPreview,
        sx: merge(
          {
            padding: 0,
            /**
             * Makes the "100%" refer to the direct parent of this element
             * instead of the parent of parent...
             */
            width: `calc(100% - 0em)`,
          },
          buttonSx,
        ),
        ...buttonProps,
      },
      content,
    );
  }, [blocking, content, handleClickPreview, previewHref, slotProps?.button]);

  return button;
};

export default Preview;
