import { BodyText } from '../Text';
import anvilState from '../../lib/consts/ANVILS';

const Anvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => (
  <>
    <BodyText text={anvil.anvil_name} />
    <BodyText
      text={anvilState.get(anvil.anvilStatus.system) ?? 'State unavailable'}
    />
  </>
);

export default Anvil;
