import anvilState from '../../lib/consts/ANVILS';

import { BodyText } from '../Text';

const Anvil: React.FC<{ anvil: AnvilListItem }> = (props) => {
  const { anvil } = props;

  return (
    <>
      <BodyText text={anvil.anvil_name} />
      <BodyText
        text={anvilState.get(anvil.anvilStatus.system) ?? 'State unavailable'}
      />
    </>
  );
};

export default Anvil;
