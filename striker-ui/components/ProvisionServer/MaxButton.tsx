import { styled } from '@mui/material';

import ContainedButton from '../ContainedButton';

const BaseStyle = styled(ContainedButton)({
  minWidth: 'unset',
  whiteSpace: 'nowrap',
});

const MaxButton: React.FC<MaxButtonProps> = (props) => {
  const { max, onClick, slotProps } = props;

  return (
    <BaseStyle onClick={onClick} {...slotProps?.button}>
      Max: {max}
    </BaseStyle>
  );
};

export default MaxButton;
