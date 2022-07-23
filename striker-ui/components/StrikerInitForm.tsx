import { FC, useRef, useState } from 'react';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GeneralInitForm from './GeneralInitForm';
import NetworkInitForm from './NetworkInitForm';
import { Panel, PanelHeader } from './Panels';
import { BodyText, HeaderText } from './Text';

const StrikerInitForm: FC = () => {
  const [requestBody, setRequestBody] = useState<
    Record<string, unknown> | undefined
  >();

  const generalInitFormRef = useRef();

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Initialize striker" />
      </PanelHeader>
      <FlexBox>
        <GeneralInitForm ref={generalInitFormRef} />
        <NetworkInitForm />
        <FlexBox row sx={{ flexDirection: 'row-reverse' }}>
          <ContainedButton
            onClick={() => {
              setRequestBody(generalInitFormRef.current);
            }}
          >
            Initialize
          </ContainedButton>
        </FlexBox>
        {requestBody && (
          <BodyText
            sx={{ fontSize: '.8em' }}
            text={JSON.stringify(requestBody, null, 2)}
          />
        )}
      </FlexBox>
    </Panel>
  );
};

export default StrikerInitForm;
