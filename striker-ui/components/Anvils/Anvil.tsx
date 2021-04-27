import { BodyText } from '../Text';
import anvilState from './CONSTS';

const Anvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  return (
    <>
      <BodyText text={anvil.anvil_name} />
      <BodyText
        text={anvilState.get(anvil.anvil_state) || 'State unavailable'}
      />
    </>
  );
};

export default Anvil;
