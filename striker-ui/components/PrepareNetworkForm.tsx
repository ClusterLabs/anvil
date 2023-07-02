import { useRouter } from 'next/router';
import { FC, useCallback, useEffect, useMemo } from 'react';

import api from '../lib/api';
import ContainedButton from './ContainedButton';
import handleAPIError from '../lib/handleAPIError';
import FlexBox from './FlexBox';
import getQueryParam from '../lib/getQueryParam';
import InputWithRef from './InputWithRef';
import MessageBox, { Message } from './MessageBox';
import NetworkInitForm from './NetworkInitForm';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { HeaderText } from './Text';
import useProtectedState from '../hooks/useProtectedState';

const PrepareNetworkForm: FC<PrepareNetworkFormProps> = ({
  expectUUID: isExpectExternalHostUUID = false,
  hostUUID,
}) => {
  const {
    isReady,
    query: { host_uuid: queryHostUUID },
  } = useRouter();

  const [hostDetail, setHostDetail] = useProtectedState<
    APIHostDetail | undefined
  >(undefined);
  const [fatalErrorMessage, setFatalErrorMessage] = useProtectedState<
    Message | undefined
  >(undefined);
  const [isLoadingHostDetail, setIsLoadingHostDetail] =
    useProtectedState<boolean>(true);
  const [previousHostUUID, setPreviousHostUUID] =
    useProtectedState<PrepareNetworkFormProps['hostUUID']>(undefined);

  const isDifferentHostUUID = useMemo(
    () => hostUUID !== previousHostUUID,
    [hostUUID, previousHostUUID],
  );
  const isReloadHostDetail = useMemo(
    () => Boolean(hostUUID) && isDifferentHostUUID,
    [hostUUID, isDifferentHostUUID],
  );

  const panelHeaderElement = useMemo(
    () => (
      <PanelHeader>
        <HeaderText>Prepare network on {hostDetail?.shortHostName}</HeaderText>
      </PanelHeader>
    ),
    [hostDetail],
  );
  const contentElement = useMemo(() => {
    let result;

    if (isLoadingHostDetail) {
      result = <Spinner mt={0} />;
    } else if (fatalErrorMessage) {
      result = <MessageBox {...fatalErrorMessage} />;
    } else {
      result = (
        <>
          {panelHeaderElement}
          <FlexBox>
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  formControlProps={{ sx: { maxWidth: '20em' } }}
                  id="prepare-network-host-name"
                  label="Host name"
                  value={hostDetail?.hostName}
                />
              }
              required
            />
            <NetworkInitForm expectHostDetail hostDetail={hostDetail} />
            <FlexBox row justifyContent="flex-end">
              <ContainedButton>Prepare network</ContainedButton>
            </FlexBox>
          </FlexBox>
        </>
      );
    }

    return result;
  }, [hostDetail, fatalErrorMessage, isLoadingHostDetail, panelHeaderElement]);

  const getHostDetail = useCallback(
    (uuid: string) => {
      setIsLoadingHostDetail(true);

      if (isLoadingHostDetail) {
        api
          .get<APIHostDetail>(`/host/${uuid}`)
          .then(({ data }) => {
            setPreviousHostUUID(data.hostUUID);
            setHostDetail(data);
          })
          .catch((error) => {
            const { children } = handleAPIError(error);

            setFatalErrorMessage({
              children: `Failed to get target host information; cannot continue. ${children}`,
              type: 'error',
            });
          })
          .finally(() => {
            setIsLoadingHostDetail(false);
          });
      }
    },
    [
      setIsLoadingHostDetail,
      isLoadingHostDetail,
      setPreviousHostUUID,
      setHostDetail,
      setFatalErrorMessage,
    ],
  );

  useEffect(() => {
    if (isExpectExternalHostUUID) {
      if (isReloadHostDetail) {
        getHostDetail(hostUUID as string);
      }
    } else if (isReady && !fatalErrorMessage) {
      if (queryHostUUID) {
        getHostDetail(getQueryParam(queryHostUUID));
      } else {
        setFatalErrorMessage({
          children: `No host UUID provided; cannot continue.`,
          type: 'error',
        });

        setIsLoadingHostDetail(false);
      }
    }
  }, [
    fatalErrorMessage,
    getHostDetail,
    hostUUID,
    isExpectExternalHostUUID,
    isReady,
    queryHostUUID,
    setFatalErrorMessage,
    setHostDetail,
    setIsLoadingHostDetail,
    isReloadHostDetail,
  ]);

  return <Panel>{contentElement}</Panel>;
};

export default PrepareNetworkForm;
