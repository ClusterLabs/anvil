import { useState, useEffect } from 'react';
// import { VncScreen } from 'react-vnc';
import VncDisplay from 'react-vnc-display';
import { Panel } from './Panels';
import { HeaderText } from './Text';

const Display = (): JSX.Element => {
  const [mounted, setMounted] = useState<boolean>(false);

  useEffect(() => {
    setMounted(typeof window !== 'undefined');
  }, [mounted]);

  return (
    <Panel>
      <HeaderText text="Display" />
      <VncDisplay
        url="wss://spain.cdot.systems:5000/"
        style={{
          width: '51vw',
          height: '70vh',
        }}
      />
    </Panel>
  );
};

export default Display;
