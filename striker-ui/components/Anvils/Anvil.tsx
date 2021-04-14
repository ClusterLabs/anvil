import { BodyText } from '../Text';

const Anvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  return (
    <>
      <BodyText text={anvil.anvil_name} />
      <BodyText text={anvil.anvil_state || 'State unavailable'} />
    </>
  );
};

export default Anvil;
