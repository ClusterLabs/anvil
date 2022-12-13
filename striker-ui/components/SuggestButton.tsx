import { FC } from 'react';

import ContainedButton from './ContainedButton';

type SuggestButtonOptionalProps = {
  show?: boolean;
};

type SuggestButtonProps = ContainedButtonProps & SuggestButtonOptionalProps;

const SUGGEST_BUTTON_DEFAULT_PROPS: Required<SuggestButtonOptionalProps> = {
  show: true,
};

const SuggestButton: FC<SuggestButtonProps> = ({
  onClick,
  show: isShow = SUGGEST_BUTTON_DEFAULT_PROPS.show,
  ...restProps
}) =>
  isShow ? (
    <ContainedButton {...{ onClick, tabIndex: -1, ...restProps }}>
      Suggest
    </ContainedButton>
  ) : (
    <></>
  );

SuggestButton.defaultProps = SUGGEST_BUTTON_DEFAULT_PROPS;

export default SuggestButton;
