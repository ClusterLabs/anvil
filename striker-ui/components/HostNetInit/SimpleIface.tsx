import { Box, styled } from '@mui/material';
import { FC, useMemo } from 'react';

import { BLACK, BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

import Decorator from '../Decorator';
import IconButton from '../IconButton';
import { MonoText } from '../Text';

const BaseIface = styled(Box)({
  alignItems: 'center',
  display: 'flex',
  flexDirection: 'row',

  '& > :not(:first-child)': {
    marginLeft: '.5em',
  },
});

const BaseFloatingIface = styled(BaseIface)({
  borderColor: GREY,
  borderRadius: BORDER_RADIUS,
  borderStyle: 'solid',
  borderWidth: '1px',
  backgroundColor: BLACK,
  padding: '.6em 1.2em',
  position: 'absolute',
  zIndex: 999,
});

const SimpleIface: FC<SimpleIfaceProps> = (props) => {
  const { iface } = props;

  const decoratorColour = useMemo(
    () => (iface.state === 'up' ? 'ok' : 'off'),
    [iface.state],
  );

  return (
    <>
      <Decorator colour={decoratorColour} />
      <MonoText>{iface.name}</MonoText>
    </>
  );
};

export const FloatingIface: FC<SimpleIfaceProps> = (props) => {
  const { boxProps, iface } = props;

  return (
    <BaseFloatingIface {...boxProps}>
      <MonoText>{iface.name}</MonoText>
    </BaseFloatingIface>
  );
};

export const AppliedIface: FC<AppliedIfaceProps> = (props) => {
  const { boxProps, iface, onClose } = props;

  return (
    <BaseIface {...boxProps}>
      <SimpleIface iface={iface} />
      <IconButton
        mapPreset="close"
        onClick={onClose}
        size="small"
        variant="normal"
      />
    </BaseIface>
  );
};
