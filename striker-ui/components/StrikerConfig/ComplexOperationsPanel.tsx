import { FC } from 'react';

import FlexBox from '../FlexBox';
import { ExpandablePanel, Panel } from '../Panels';
import { BodyText } from '../Text';

const ComplexOperationsPanel: FC = () => (
  <Panel>
    <ExpandablePanel header={<BodyText>Configure striker peers</BodyText>}>
      <FlexBox>
        <BodyText>Inbound connections</BodyText>
      </FlexBox>
    </ExpandablePanel>
  </Panel>
);

export default ComplexOperationsPanel;
