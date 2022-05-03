import { Box, BoxProps } from '@mui/material';
import {
  Error as ErrorIcon,
  Info as InfoIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';

import {
  BLACK,
  BORDER_RADIUS,
  GREY,
  PURPLE,
  RED,
  TEXT,
} from '../lib/consts/DEFAULT_THEME';

import { BodyText } from './Text';

type MessageBoxType = 'error' | 'info' | 'warning';

type MessageBoxProps = BoxProps & {
  text: string;
  type: MessageBoxType;
};

const MESSAGE_BOX_CLASS_PREFIX = 'MessageBox';

const MESSAGE_BOX_CLASSES: Record<MessageBoxType, string> = {
  error: `${MESSAGE_BOX_CLASS_PREFIX}-error`,
  info: `${MESSAGE_BOX_CLASS_PREFIX}-info`,
  warning: `${MESSAGE_BOX_CLASS_PREFIX}-warning`,
};

const MESSAGE_BOX_TYPE_MAP_TO_ICON = {
  error: <ErrorIcon />,
  info: <InfoIcon />,
  warning: <WarningIcon />,
};

const MessageBox = ({
  type,
  text,
  ...boxProps
}: MessageBoxProps): JSX.Element => {
  const { sx: boxSx } = boxProps;

  const buildMessageBoxClasses = (messageBoxType: MessageBoxType) =>
    MESSAGE_BOX_CLASSES[messageBoxType];

  const buildMessageIcon = (messageBoxType: MessageBoxType) =>
    MESSAGE_BOX_TYPE_MAP_TO_ICON[messageBoxType] === undefined
      ? MESSAGE_BOX_TYPE_MAP_TO_ICON.info
      : MESSAGE_BOX_TYPE_MAP_TO_ICON[messageBoxType];

  const buildMessage = (message: string, messageBoxType: MessageBoxType) => (
    <BodyText inverted={messageBoxType === 'info'} text={message} />
  );

  const combinedBoxSx: BoxProps['sx'] = {
    alignItems: 'center',
    borderRadius: BORDER_RADIUS,
    display: 'flex',
    flexDirection: 'row',
    padding: '.3em .6em',

    '& > *': {
      color: TEXT,
    },

    '& > :first-child': {
      marginRight: '.3em',
    },

    [`&.${MESSAGE_BOX_CLASSES.error}`]: {
      backgroundColor: RED,
    },

    [`&.${MESSAGE_BOX_CLASSES.info}`]: {
      backgroundColor: GREY,

      '& > :first-child': {
        color: `${BLACK}`,
      },
    },

    [`&.${MESSAGE_BOX_CLASSES.warning}`]: {
      backgroundColor: PURPLE,
    },

    ...boxSx,
  };

  return (
    <Box
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        ...boxProps,
        className: buildMessageBoxClasses(type),
        sx: combinedBoxSx,
      }}
    >
      {buildMessageIcon(type)}
      {buildMessage(text, type)}
    </Box>
  );
};

export type { MessageBoxProps, MessageBoxType };

export default MessageBox;
