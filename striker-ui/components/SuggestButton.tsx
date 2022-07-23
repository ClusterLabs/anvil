import { FC } from 'react';

import ContainedButton, { ContainedButtonProps } from './ContainedButton';

const SuggestButton: FC<ContainedButtonProps> = ({ onClick, ...restProps }) =>
  onClick ? (
    <ContainedButton {...{ onClick, tabIndex: -1, ...restProps }}>
      Suggest
    </ContainedButton>
  ) : (
    <></>
  );

export default SuggestButton;
