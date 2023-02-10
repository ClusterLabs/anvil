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
import useProtect from '../hooks/useProtect';
import useProtectedState from '../hooks/useProtectedState';

const PrepareNetworkForm: FC<PrepareNetworkFormProps> = ({
  expectUUID: isExpectExternalHostUUID = false,
  hostUUID,
}) => {
  const { protect } = useProtect();

  const {
    isReady,
    query: { host_uuid: queryHostUUID },
  } = useRouter();

  const [dataHostDetail, setDataHostDetail] = useProtectedState<
    APIHostDetail | undefined
  >(undefined, protect);
  const [fatalErrorMessage, setFatalErrorMessage] = useProtectedState<
    Message | undefined
  >(undefined, protect);
  const [isLoading, setIsLoading] = useProtectedState<boolean>(true, protect);
  const [previousHostUUID, setPreviousHostUUID] = useProtectedState<
    PrepareNetworkFormProps['hostUUID']
  >(undefined, protect);

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
        <HeaderText>
          Prepare network on {dataHostDetail?.shortHostName}
        </HeaderText>
      </PanelHeader>
    ),
    [dataHostDetail],
  );
  const contentElement = useMemo(() => {
    let result;

    if (isLoading) {
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
                  value={dataHostDetail?.hostName}
                />
              }
              required
            />
            <NetworkInitForm hostDetail={dataHostDetail} />
            <FlexBox row justifyContent="flex-end">
              <ContainedButton>Prepare network</ContainedButton>
            </FlexBox>
          </FlexBox>
        </>
      );
    }

    return result;
  }, [dataHostDetail, fatalErrorMessage, isLoading, panelHeaderElement]);

  const getHostDetail = useCallback(
    (uuid: string) => {
      setIsLoading(true);

      if (isLoading) {
        api
          .get<APIHostDetail>(`/host/${uuid}`)
          .then(({ data }) => {
            setPreviousHostUUID(data.hostUUID);
            setDataHostDetail(data);
          })
          .catch((error) => {
            const { children } = handleAPIError(error);

            setFatalErrorMessage({
              children: `Failed to get target host information; cannot continue. ${children}`,
              type: 'error',
            });
          })
          .finally(() => {
            setIsLoading(false);
          });
      }
    },
    [
      setIsLoading,
      isLoading,
      setPreviousHostUUID,
      setDataHostDetail,
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

        setIsLoading(false);
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
    setDataHostDetail,
    setIsLoading,
    isReloadHostDetail,
  ]);

  return <Panel>{contentElement}</Panel>;
};

export default PrepareNetworkForm;
