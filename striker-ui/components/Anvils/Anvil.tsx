import { BodyText } from '../Text';
import anvilState from '../../lib/consts/ANVILS';

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
