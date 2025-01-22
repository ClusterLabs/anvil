import { Assignment as AssignmentIcon } from '@mui/icons-material';
import { Grid } from '@mui/material';
import { useRouter } from 'next/router';
import { FC, useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { BLACK } from '../lib/consts/DEFAULT_THEME';

import api from '../lib/api';
import ConfirmDialog from './ConfirmDialog';
import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import GeneralInitForm, {
  GeneralInitFormForwardedRefContent,
  GeneralInitFormValues,
} from './GeneralInitForm';
import handleAPIError from '../lib/handleAPIError';
import IconButton from './IconButton';
import IconWithIndicator, {
  IconWithIndicatorForwardedRefContent,
} from './IconWithIndicator';
import JobSummary, { JobSummaryForwardedRefContent } from './JobSummary';
import Link from './Link';
import MessageBox, { Message } from './MessageBox';
import NetworkInitForm, {
  NetworkInitFormForwardedRefContent,
  NetworkInitFormValues,
} from './NetworkInitForm';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { BodyText, HeaderText, InlineMonoText, MonoText } from './Text';

const StrikerInitForm: FC = () => {
  const {
    isReady,
    query: { re },
  } = useRouter();

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
  const [hostNumber, setHostNumber] = useState<string | undefined>();

  const [hostDetail, setHostDetail] = useState<APIHostDetail | undefined>();

  // Make sure the fetch for host detail only happens once.
  const allowGetHostDetail = useRef<boolean>(true);

  const generalInitFormRef = useRef<GeneralInitFormForwardedRefContent>({});
  const networkInitFormRef = useRef<NetworkInitFormForwardedRefContent>({});

  const jobIconRef = useRef<IconWithIndicatorForwardedRefContent>({});
  const jobSummaryRef = useRef<JobSummaryForwardedRefContent>({});

  const [panelTitle, setPanelTitle] = useState<string>('Loading...');

  const reconfig = useMemo<boolean>(() => Boolean(re), [re]);

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

  useEffect(() => {
    if (!isReady) return;

    if (!reconfig) {
      setPanelTitle('Initialize striker');

      return;
    }

    if (!allowGetHostDetail.current) return;

    allowGetHostDetail.current = false;

    api
      .get<APIHostDetail>('/host/local')
      .then(({ data }) => {
        setHostDetail(data);
        setPanelTitle(`Reconfigure ${data.shortHostName}`);
      })
      .catch((error) => {
        const emsg = handleAPIError(error);

        emsg.children = <>Failed to get host detail data. {emsg.children}</>;

        setSubmitMessage(emsg);
      });
  }, [isReady, reconfig, setHostDetail]);

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>{panelTitle}</HeaderText>
          <IconButton
            onClick={({ currentTarget }) => {
              jobSummaryRef.current.setAnchor?.call(null, currentTarget);
              jobSummaryRef.current.setOpen?.call(null, true);
            }}
            variant="normal"
          >
            <IconWithIndicator icon={AssignmentIcon} ref={jobIconRef} />
          </IconButton>
        </PanelHeader>
        <FlexBox>
          <GeneralInitForm
            expectHostDetail={reconfig}
            hostDetail={hostDetail}
            onHostNumberBlurAppend={({ target: { value } }) => {
              setHostNumber(value);
            }}
            ref={generalInitFormRef}
            toggleSubmitDisabled={(testResult) => {
              if (testResult !== isGeneralInitFormValid) {
                setIsGeneralInitFormValid(testResult);
                toggleSubmitDisabled(testResult, isNetworkInitFormValid);
              }
            }}
          />
          <NetworkInitForm
            expectHostDetail={reconfig}
            hostDetail={hostDetail}
            hostSequence={hostNumber}
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
                        <Grid columns={{ xs: 2 }} container key={key} item>
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
              <MonoText>{requestBody?.dns}</MonoText>
            </Grid>
          </Grid>
        }
        dialogProps={{ open: isOpenConfirm }}
        onCancelAppend={() => {
          setIsOpenConfirm(false);
        }}
        onProceedAppend={() => {
          setSubmitMessage(undefined);
          setIsSubmittingForm(true);
          setIsOpenConfirm(false);

          api
            .put('/init', requestBody)
            .then(() => {
              setIsSubmittingForm(false);
              setSubmitMessage({
                children: reconfig ? (
                  <>Successfully initiated reconfiguration.</>
                ) : (
                  <>
                    Successfully registered the configuration job! You can check
                    the progress at the top right icon. Once the job completes,
                    you can access the{' '}
                    <Link
                      href="/login"
                      sx={{ color: BLACK, display: 'inline-flex' }}
                    >
                      login page
                    </Link>
                    .
                  </>
                ),
                type: 'info',
              });
            })
            .catch((error) => {
              const errorMessage = handleAPIError(error);

              setSubmitMessage(errorMessage);
              setIsSubmittingForm(false);
            });
        }}
        titleText="Confirm striker initialization"
      />
      <JobSummary
        getJobUrl={() => `/init/job`}
        onFetchSuccessAppend={(jobs) => {
          jobIconRef.current.indicate?.call(null, Object.keys(jobs).length > 0);
        }}
        ref={jobSummaryRef}
      />
    </>
  );
};

export default StrikerInitForm;
