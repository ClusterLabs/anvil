import { Box, styled } from '@mui/material';
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

type MessageBoxProps = {
  text: string;
  type: MessageBoxType;
};

const MESSAGE_BOX_CLASS_PREFIX = 'MessageBox';

const MESSAGE_BOX_CLASSES: Record<MessageBoxType, string> = {
  error: `${MESSAGE_BOX_CLASS_PREFIX}-error`,
  info: `${MESSAGE_BOX_CLASS_PREFIX}-info`,
  warning: `${MESSAGE_BOX_CLASS_PREFIX}-warning`,
};

const StyledBox = styled(Box)({
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
});

const MessageBox = ({ type, text }: MessageBoxProps): JSX.Element => {
  const buildMessageBoxClasses = (messageBoxType: MessageBoxType) =>
    MESSAGE_BOX_CLASSES[messageBoxType];

  const buildMessageIcon = (messageBoxType: MessageBoxType) => {
    let messageIcon;

    switch (messageBoxType) {
      case 'error':
        messageIcon = <ErrorIcon />;
        break;
      case 'warning':
        messageIcon = <WarningIcon />;
        break;
      default:
        messageIcon = <InfoIcon />;
    }

    return messageIcon;
  };

  const buildMessage = (message: string, messageBoxType: MessageBoxType) => (
    <BodyText inverted={messageBoxType === 'info'} text={message} />
  );

  return (
    <StyledBox className={buildMessageBoxClasses(type)}>
      {buildMessageIcon(type)}
      {buildMessage(text, type)}
    </StyledBox>
  );
};

export type { MessageBoxProps, MessageBoxType };

export default MessageBox;
