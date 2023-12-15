import { FC } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
} from '@mui/material';
import { Close as MUICloseIcon } from '@mui/icons-material';

import { BLACK, BORDER_RADIUS, GREY } from '../lib/consts/DEFAULT_THEME';

import { MonoText } from './Text';

type BriefNetworkInterfaceOptionalProps = {
  isFloating?: boolean;
  onClose?: MUIIconButtonProps['onClick'];
};

const BRIEF_NETWORK_INTERFACE_DEFAULT_PROPS: Required<
  Omit<BriefNetworkInterfaceOptionalProps, 'onClose'>
> &
  Pick<BriefNetworkInterfaceOptionalProps, 'onClose'> = {
  isFloating: false,
  onClose: undefined,
};

const BriefNetworkInterface: FC<
  MUIBoxProps &
    BriefNetworkInterfaceOptionalProps & {
      networkInterface: NetworkInterfaceOverviewMetadata;
    }
> = ({
  isFloating,
  networkInterface: { networkInterfaceName },
  onClose,
  sx: rootSx,
  ...restRootProps
}) => {
  const draggingSx: MUIBoxProps['sx'] = isFloating
    ? {
        borderColor: GREY,
        borderRadius: BORDER_RADIUS,
        borderStyle: 'solid',
        borderWidth: '1px',
        backgroundColor: BLACK,
        padding: '.6em 1.2em',
      }
    : {};

  return (
    <MUIBox
      {...{
        sx: {
          display: 'flex',
          flexDirection: 'row',
          alignItems: 'center',

          '& > :not(:first-child)': {
            marginLeft: '.5em',
          },

          ...draggingSx,
          ...rootSx,
        },

        ...restRootProps,
      }}
    >
      <MonoText>{networkInterfaceName}</MonoText>
      {onClose && (
        <MUIIconButton onClick={onClose} size="small" sx={{ color: GREY }}>
          <MUICloseIcon />
        </MUIIconButton>
      )}
    </MUIBox>
  );
};

BriefNetworkInterface.defaultProps = BRIEF_NETWORK_INTERFACE_DEFAULT_PROPS;

export default BriefNetworkInterface;
