import { FC, useCallback, useMemo, useRef, useState } from 'react';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GeneralInitForm, {
  GeneralInitFormForwardRefContent,
} from './GeneralInitForm';
import mainAxiosInstance from '../lib/singletons/mainAxiosInstance';
import MessageBox, { Message } from './MessageBox';
import NetworkInitForm, {
  NetworkInitFormForwardRefContent,
} from './NetworkInitForm';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { HeaderText } from './Text';

const StrikerInitForm: FC = () => {
  const [submitMessage, setSubmitMessage] = useState<Message | undefined>();
  const [isDisableSubmit, setIsDisableSubmit] = useState<boolean>(true);
  const [isGeneralInitFormValid, setIsGeneralInitFormValid] =
    useState<boolean>(false);
  const [isNetworkInitFormValid, setIsNetworkInitFormValid] =
    useState<boolean>(false);
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
            disabled={isDisableSubmit}
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
                })
                .catch((reason) => {
                  setSubmitMessage({
                    children: `Failed to submit; ${reason}`,
                    type: 'error',
                  });

                  setIsSubmittingForm(false);
                });
            }}
          >
            Initialize
          </ContainedButton>
        </FlexBox>
      ),
    [isDisableSubmit, isSubmittingForm],
  );

  const toggleSubmitDisabled = useCallback((...testResults: boolean[]) => {
    setIsDisableSubmit(!testResults.every((testResult) => testResult));
  }, []);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Initialize striker" />
      </PanelHeader>
      <FlexBox>
        <GeneralInitForm
          ref={generalInitFormRef}
          toggleSubmitDisabled={(testResult) => {
            if (testResult !== isGeneralInitFormValid) {
              setIsGeneralInitFormValid(testResult);
              toggleSubmitDisabled(testResult, isNetworkInitFormValid);
            }
          }}
        />
        <NetworkInitForm
          ref={networkInitFormRef}
          toggleSubmitDisabled={(testResult) => {
            if (testResult !== isNetworkInitFormValid) {
              setIsNetworkInitFormValid(testResult);
              toggleSubmitDisabled(isGeneralInitFormValid, testResult);
            }
          }}
        />
        {submitMessage && (
          <MessageBox
            {...submitMessage}
            onClose={() => setSubmitMessage(undefined)}
          />
        )}
        {buildSubmitSection}
      </FlexBox>
    </Panel>
  );
};

export default StrikerInitForm;
