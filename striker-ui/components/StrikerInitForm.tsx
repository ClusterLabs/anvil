import { Grid } from '@mui/material';
import { FC, useCallback, useMemo, useRef, useState } from 'react';

import ConfirmDialog from './ConfirmDialog';
import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GeneralInitForm, {
  GeneralInitFormForwardedRefContent,
  GeneralInitFormValues,
} from './GeneralInitForm';
import mainAxiosInstance from '../lib/singletons/mainAxiosInstance';
import MessageBox, { Message } from './MessageBox';
import NetworkInitForm, {
  NetworkInitFormForwardedRefContent,
  NetworkInitFormValues,
} from './NetworkInitForm';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { BodyText, HeaderText, InlineMonoText, MonoText } from './Text';

const StrikerInitForm: FC = () => {
  const [submitMessage, setSubmitMessage] = useState<Message | undefined>();
  const [requestBody, setRequestBody] = useState<
    (GeneralInitFormValues & NetworkInitFormValues) | undefined
  >();
  const [isOpenConfirm, setIsOpenConfirm] = useState<boolean>(false);
  const [isDisableSubmit, setIsDisableSubmit] = useState<boolean>(true);
  const [isGeneralInitFormValid, setIsGeneralInitFormValid] =
    useState<boolean>(false);
  const [isNetworkInitFormValid, setIsNetworkInitFormValid] =
    useState<boolean>(false);
  const [isSubmittingForm, setIsSubmittingForm] = useState<boolean>(false);

  const generalInitFormRef = useRef<GeneralInitFormForwardedRefContent>({});
  const networkInitFormRef = useRef<NetworkInitFormForwardedRefContent>({});

  const buildSubmitSection = useMemo(
    () =>
      isSubmittingForm ? (
        <Spinner />
      ) : (
        <FlexBox row sx={{ flexDirection: 'row-reverse' }}>
          <ContainedButton
            disabled={isDisableSubmit}
            onClick={() => {
              setRequestBody({
                ...(generalInitFormRef.current.get?.call(null) ?? {}),
                ...(networkInitFormRef.current.get?.call(null) ?? {
                  networks: [],
                }),
              });

              setIsOpenConfirm(true);
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
    <>
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
      <ConfirmDialog
        actionProceedText="Initialize"
        content={
          <Grid container spacing=".6em" columns={{ xs: 2 }}>
            <Grid item xs={1}>
              <BodyText>Organization name</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.organizationName}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText>Organization prefix</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.organizationPrefix}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText>Striker number</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.hostNumber}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText>Domain name</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.domainName}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText>Host name</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.hostName}</MonoText>
            </Grid>
            <Grid item sx={{ marginTop: '1.4em' }} xs={2}>
              <BodyText>Networks</BodyText>
            </Grid>
            {requestBody?.networks.map(
              ({
                inputUUID,
                interfaces,
                ipAddress,
                name,
                subnetMask,
                type,
                typeCount,
              }) => (
                <Grid key={`network-confirm-${inputUUID}`} item xs={1}>
                  <Grid container spacing=".6em" columns={{ xs: 2 }}>
                    <Grid item xs={2}>
                      <BodyText>
                        {name} (
                        <InlineMonoText>
                          {`${type.toUpperCase()}${typeCount}`}
                        </InlineMonoText>
                        )
                      </BodyText>
                    </Grid>
                    {interfaces.map((iface, ifaceIndex) => {
                      let key = `network-confirm-${inputUUID}-interface${ifaceIndex}`;
                      let ifaceName = 'none';

                      if (iface) {
                        const { networkInterfaceName, networkInterfaceUUID } =
                          iface;

                        key = `${key}-${networkInterfaceUUID}`;
                        ifaceName = networkInterfaceName;
                      }

                      return (
                        <Grid container key={key} item>
                          <Grid item xs={1}>
                            <BodyText>{`Link ${ifaceIndex + 1}`}</BodyText>
                          </Grid>
                          <Grid item xs={1}>
                            <MonoText>{ifaceName}</MonoText>
                          </Grid>
                        </Grid>
                      );
                    })}
                    <Grid item xs={2}>
                      <MonoText>{`${ipAddress}/${subnetMask}`}</MonoText>
                    </Grid>
                  </Grid>
                </Grid>
              ),
            )}
            <Grid item sx={{ marginBottom: '1.4em' }} xs={2} />
            <Grid item xs={1}>
              <BodyText>Gateway</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.gateway}</MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText>Gateway network</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>
                {requestBody?.gatewayInterface?.toUpperCase()}
              </MonoText>
            </Grid>
            <Grid item xs={1}>
              <BodyText>Domain name server(s)</BodyText>
            </Grid>
            <Grid item xs={1}>
              <MonoText>{requestBody?.domainNameServerCSV}</MonoText>
            </Grid>
          </Grid>
        }
        dialogProps={{ open: isOpenConfirm }}
        onCancel={() => {
          setIsOpenConfirm(false);
        }}
        onProceed={() => {
          setSubmitMessage(undefined);
          setIsSubmittingForm(true);
          setIsOpenConfirm(false);

          mainAxiosInstance
            .put('/command/initialize-striker', JSON.stringify(requestBody), {
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
        titleText="Confirm striker initialization"
      />
    </>
  );
};

export default StrikerInitForm;
