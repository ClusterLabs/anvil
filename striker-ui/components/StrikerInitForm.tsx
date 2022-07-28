import { FC, useRef, useState } from 'react';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GeneralInitForm, {
  GeneralInitFormForwardRefContent,
} from './GeneralInitForm';
import NetworkInitForm, {
  NetworkInitFormForwardRefContent,
} from './NetworkInitForm';
import { Panel, PanelHeader } from './Panels';
import { BodyText, HeaderText } from './Text';

const StrikerInitForm: FC = () => {
  const [requestBody, setRequestBody] = useState<
    Record<string, unknown> | undefined
  >();

  const generalInitFormRef = useRef<GeneralInitFormForwardRefContent>({});
  const networkInitFormRef = useRef<NetworkInitFormForwardRefContent>({});

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Initialize striker" />
      </PanelHeader>
      <FlexBox>
        <GeneralInitForm ref={generalInitFormRef} />
        <NetworkInitForm ref={networkInitFormRef} />
        <FlexBox row sx={{ flexDirection: 'row-reverse' }}>
          <ContainedButton
            onClick={() => {
              setRequestBody({
                ...(generalInitFormRef.current.get?.call(null) ?? {}),
                ...(networkInitFormRef.current.get?.call(null) ?? {}),
              });
            }}
          >
            Initialize
          </ContainedButton>
        </FlexBox>
        {requestBody && (
          <pre>
            <BodyText
              sx={{ fontSize: '.8em' }}
              text={JSON.stringify(requestBody, null, 2)}
            />
          </pre>
        )}
      </FlexBox>
    </Panel>
  );
};

export default StrikerInitForm;
