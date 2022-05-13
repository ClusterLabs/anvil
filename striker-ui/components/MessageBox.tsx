import { FC, useState } from 'react';
import { Box, BoxProps, IconButton } from '@mui/material';
import {
  Close as CloseIcon,
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

type MessageBoxOptionalProps = {
  isAllowClose?: boolean;
  type?: MessageBoxType;
};

type MessageBoxProps = BoxProps &
  MessageBoxOptionalProps & {
    text: string;
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

const MESSAGE_BOX_DEFAULT_PROPS: Required<MessageBoxOptionalProps> = {
  isAllowClose: false,
  type: 'info',
};

const MessageBox: FC<MessageBoxProps> = ({
  isAllowClose,
  type = MESSAGE_BOX_DEFAULT_PROPS.type,
  text,
  ...boxProps
}) => {
  const { sx: boxSx } = boxProps;

  const [isShow, setIsShow] = useState<boolean>(true);

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

    '& > :nth-child(2)': {
      flexGrow: 1,
    },

    [`&.${MESSAGE_BOX_CLASSES.error}`]: {
      backgroundColor: RED,
    },

    [`&.${MESSAGE_BOX_CLASSES.info}`]: {
      backgroundColor: GREY,

      '& > *': {
        color: `${BLACK}`,
      },
    },

    [`&.${MESSAGE_BOX_CLASSES.warning}`]: {
      backgroundColor: PURPLE,
    },

    ...boxSx,
  };

  return isShow ? (
    <Box
      {...{
        ...boxProps,
        className: buildMessageBoxClasses(type),
        sx: combinedBoxSx,
      }}
    >
      {buildMessageIcon(type)}
      {buildMessage(text, type)}
      {isAllowClose && (
        <IconButton
          onClick={() => {
            setIsShow(false);
          }}
        >
          <CloseIcon sx={{ fontSize: '1.25rem' }} />
        </IconButton>
      )}
    </Box>
  ) : (
    <></>
  );
};

MessageBox.defaultProps = MESSAGE_BOX_DEFAULT_PROPS;

export type { MessageBoxProps, MessageBoxType };

export default MessageBox;
