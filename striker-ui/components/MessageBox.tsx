import {
  Close as MuiCloseIcon,
  Error as MuiErrorIcon,
  Info as MuiInfoIcon,
  Warning as MuiWarningIcon,
} from '@mui/icons-material';
import {
  Box as MuiBox,
  BoxProps as MuiBoxProps,
  IconButton as MuiIconButton,
  IconButtonProps as MuiIconButtonProps,
} from '@mui/material';
import { useCallback, useMemo, useState } from 'react';

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
  onClose?: MuiIconButtonProps['onClick'];
  onCloseAppend?: MuiIconButtonProps['onClick'];
  text?: string;
  type?: MessageBoxType;
};

type MessageBoxProps = MuiBoxProps & MessageBoxOptionalProps;

type Message = Pick<MessageBoxProps, 'children' | 'type'>;

const MESSAGE_BOX_CLASS_PREFIX = 'MessageBox';

const MESSAGE_BOX_CLASSES: Record<MessageBoxType, string> = {
  error: `${MESSAGE_BOX_CLASS_PREFIX}-error`,
  info: `${MESSAGE_BOX_CLASS_PREFIX}-info`,
  warning: `${MESSAGE_BOX_CLASS_PREFIX}-warning`,
};

const MESSAGE_BOX_TYPE_MAP_TO_ICON = {
  error: <MuiErrorIcon />,
  info: <MuiInfoIcon />,
  warning: <MuiWarningIcon />,
};

const MessageBox: React.FC<MessageBoxProps> = ({
  children,
  isAllowClose = false,
  isShowInitially = true,
  onClose,
  onCloseAppend,
  type = 'info',
  text,
  ...boxProps
}) => {
  const { sx: boxSx } = boxProps;

  const [isShow, setIsShow] = useState<boolean>(isShowInitially);

  const isShowCloseButton: boolean = useMemo(
    () => isAllowClose || onClose !== undefined || onCloseAppend !== undefined,
    [isAllowClose, onClose, onCloseAppend],
  );

  const buildMessageBoxClasses = useCallback(
    (messageBoxType: MessageBoxType) => MESSAGE_BOX_CLASSES[messageBoxType],
    [],
  );
  const buildMessageIcon = useCallback(
    (messageBoxType: MessageBoxType) =>
      MESSAGE_BOX_TYPE_MAP_TO_ICON[messageBoxType] === undefined
        ? MESSAGE_BOX_TYPE_MAP_TO_ICON.info
        : MESSAGE_BOX_TYPE_MAP_TO_ICON[messageBoxType],
    [],
  );
  const buildMessage = useCallback(
    (messageBoxType: MessageBoxType, message: React.ReactNode = children) => (
      <BodyText inverted={messageBoxType === 'info'}>{message}</BodyText>
    ),
    [children],
  );

  const combinedBoxSx: MuiBoxProps['sx'] = useMemo(
    () => ({
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
    }),
    [boxSx],
  );

  return (
    isShow && (
      <MuiBox
        {...{
          ...boxProps,
          className: buildMessageBoxClasses(type),
          sx: combinedBoxSx,
        }}
      >
        {buildMessageIcon(type)}
        {buildMessage(type, text)}
        {isShowCloseButton && (
          <MuiIconButton
            onClick={
              onClose ??
              ((...args) => {
                setIsShow(false);
                onCloseAppend?.call(null, ...args);
              })
            }
          >
            <MuiCloseIcon sx={{ fontSize: '1.25rem' }} />
          </MuiIconButton>
        )}
      </MuiBox>
    )
  );
};

export type { Message, MessageBoxProps, MessageBoxType };

export default MessageBox;
