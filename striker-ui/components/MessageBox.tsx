import { FC, useState } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
} from '@mui/material';
import {
  Close as MUICloseIcon,
  Error as MUIErrorIcon,
  Info as MUIInfoIcon,
  Warning as MUIWarningIcon,
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
  isShowInitially?: boolean;
  isAllowClose?: boolean;
  onClose?: MUIIconButtonProps['onClick'];
  onCloseAppend?: MUIIconButtonProps['onClick'];
  type?: MessageBoxType;
};

type MessageBoxProps = MUIBoxProps &
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
  error: <MUIErrorIcon />,
  info: <MUIInfoIcon />,
  warning: <MUIWarningIcon />,
};

const MESSAGE_BOX_DEFAULT_PROPS: Required<
  Omit<MessageBoxOptionalProps, 'onClose' | 'onCloseAppend'>
> &
  Pick<MessageBoxOptionalProps, 'onClose' | 'onCloseAppend'> = {
  isShowInitially: true,
  isAllowClose: false,
  onClose: undefined,
  onCloseAppend: undefined,
  type: 'info',
};

const MessageBox: FC<MessageBoxProps> = ({
  isAllowClose,
  isShowInitially = MESSAGE_BOX_DEFAULT_PROPS.isShowInitially,
  onClose,
  onCloseAppend,
  type = MESSAGE_BOX_DEFAULT_PROPS.type,
  text,
  ...boxProps
}) => {
  const { sx: boxSx } = boxProps;

  const [isShow, setIsShow] = useState<boolean>(isShowInitially);

  const isShowCloseButton = isAllowClose || onClose || onCloseAppend;

  const buildMessageBoxClasses = (messageBoxType: MessageBoxType) =>
    MESSAGE_BOX_CLASSES[messageBoxType];

  const buildMessageIcon = (messageBoxType: MessageBoxType) =>
    MESSAGE_BOX_TYPE_MAP_TO_ICON[messageBoxType] === undefined
      ? MESSAGE_BOX_TYPE_MAP_TO_ICON.info
      : MESSAGE_BOX_TYPE_MAP_TO_ICON[messageBoxType];

  const buildMessage = (message: string, messageBoxType: MessageBoxType) => (
    <BodyText inverted={messageBoxType === 'info'} text={message} />
  );

  const combinedBoxSx: MUIBoxProps['sx'] = {
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
    <MUIBox
      {...{
        ...boxProps,
        className: buildMessageBoxClasses(type),
        sx: combinedBoxSx,
      }}
    >
      {buildMessageIcon(type)}
      {buildMessage(text, type)}
      {isShowCloseButton && (
        <MUIIconButton
          onClick={
            onClose ??
            ((...args) => {
              setIsShow(false);
              onCloseAppend?.call(null, ...args);
            })
          }
        >
          <MUICloseIcon sx={{ fontSize: '1.25rem' }} />
        </MUIIconButton>
      )}
    </MUIBox>
  ) : (
    <></>
  );
};

MessageBox.defaultProps = MESSAGE_BOX_DEFAULT_PROPS;

export type { MessageBoxProps, MessageBoxType };

export default MessageBox;
