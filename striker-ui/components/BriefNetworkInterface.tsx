import { FC } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
} from '@mui/material';
import { Close as MUICloseIcon } from '@mui/icons-material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import Decorator from './Decorator';
import { BodyText } from './Text';

type BriefNetworkInterfaceOptionalProps = {
  onClose?: MUIIconButtonProps['onClick'];
};

const BRIEF_NETWORK_INTERFACE_DEFAULT_PROPS: Required<
  Omit<BriefNetworkInterfaceOptionalProps, 'onClose'>
> &
  Pick<BriefNetworkInterfaceOptionalProps, 'onClose'> = {
  onClose: undefined,
};

const BriefNetworkInterface: FC<
  MUIBoxProps &
    BriefNetworkInterfaceOptionalProps & {
      networkInterface: NetworkInterfaceOverviewMetadata;
    }
> = ({
  networkInterface: { networkInterfaceName, networkInterfaceState },
  onClose,
  sx: rootSx,
  ...restRootProps
}) => (
  <MUIBox
    {...{
      sx: {
        display: 'flex',
        flexDirection: 'row',

        '& > :not(:first-child)': {
          alignSelf: 'center',
          marginLeft: '.5em',
        },

        ...rootSx,
      },

      ...restRootProps,
    }}
  >
    <Decorator
      colour={networkInterfaceState === 'up' ? 'ok' : 'off'}
      sx={{ height: 'auto' }}
    />
    <BodyText text={networkInterfaceName} />
    {onClose && (
      <MUIIconButton onClick={onClose} size="small" sx={{ color: GREY }}>
        <MUICloseIcon />
      </MUIIconButton>
    )}
  </MUIBox>
);

BriefNetworkInterface.defaultProps = BRIEF_NETWORK_INTERFACE_DEFAULT_PROPS;

export default BriefNetworkInterface;
