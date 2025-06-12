import ContainedButton from './ContainedButton';

type SuggestButtonOptionalProps = {
  show?: boolean;
};

type SuggestButtonProps = ContainedButtonProps & SuggestButtonOptionalProps;

const SuggestButton: React.FC<SuggestButtonProps> = ({
  onClick,
  show = true,
  ...restProps
}) => {
  if (!show) {
    return null;
  }

  return (
    <ContainedButton onClick={onClick} tabIndex={-1} {...restProps}>
      Suggest
    </ContainedButton>
  );
};

export default SuggestButton;
