import { FC, useMemo, useRef, useState } from 'react';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GeneralInitForm, {
  GeneralInitFormForwardRefContent,
} from './GeneralInitForm';
import mainAxiosInstance from '../lib/singletons/mainAxiosInstance';
import NetworkInitForm, {
  NetworkInitFormForwardRefContent,
} from './NetworkInitForm';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { HeaderText } from './Text';

const StrikerInitForm: FC = () => {
  const [isSubmittingForm, setIsSubmittingForm] = useState<boolean>(false);

  const generalInitFormRef = useRef<GeneralInitFormForwardRefContent>({});
  const networkInitFormRef = useRef<NetworkInitFormForwardRefContent>({});

  const buildSubmitSection = useMemo(
    () =>
      isSubmittingForm ? (
        <Spinner />
      ) : (
        <FlexBox row sx={{ flexDirection: 'row-reverse' }}>
          <ContainedButton
            onClick={() => {
              setIsSubmittingForm(true);

              const requestBody: string = JSON.stringify({
                ...(generalInitFormRef.current.get?.call(null) ?? {}),
                ...(networkInitFormRef.current.get?.call(null) ?? {}),
              });

              mainAxiosInstance
                .put('/command/initialize-striker', requestBody, {
                  headers: { 'Content-Type': 'application/json' },
                })
                .then(() => {
                  setIsSubmittingForm(false);
                });
            }}
          >
            Initialize
          </ContainedButton>
        </FlexBox>
      ),
    [isSubmittingForm],
  );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Initialize striker" />
      </PanelHeader>
      <FlexBox>
        <GeneralInitForm ref={generalInitFormRef} />
        <NetworkInitForm ref={networkInitFormRef} />
        {buildSubmitSection}
      </FlexBox>
    </Panel>
  );
};

export default StrikerInitForm;
