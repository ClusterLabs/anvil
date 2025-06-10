import { styled } from '@mui/material';

import ContainedButton from '../ContainedButton';

const BaseStyle = styled(ContainedButton)({
  minWidth: 'unset',
  whiteSpace: 'nowrap',
});

const MaxButton: React.FC<React.PropsWithChildren<MaxButtonProps>> = (
  props,
) => {
  const { children, onClick, slotProps } = props;

  return (
    <BaseStyle onClick={onClick} {...slotProps?.button}>
      Max: {children}
    </BaseStyle>
  );
};

export default MaxButton;
