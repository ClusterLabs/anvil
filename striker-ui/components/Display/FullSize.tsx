import VncDisplay from 'react-vnc-display';
import { Panel } from '../Panels';
import { HeaderText } from '../Text';

const Display = (): JSX.Element => {
  return (
    <Panel>
      <HeaderText text="Display" />
      <VncDisplay
        url="wss://spain.cdot.systems:5000/"
        style={{
          width: '50vw',
          height: '70vh',
        }}
      />
    </Panel>
  );
};

export default Display;
