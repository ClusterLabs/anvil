import { withRouter } from 'next/router';
import { useEffect, useMemo } from 'react';

import api from '../lib/api';
import ContainedButton from './ContainedButton';
import handleAPIError from '../lib/handleAPIError';
import FlexBox from './FlexBox';
import InputWithRef from './InputWithRef';
import MessageBox, { Message } from './MessageBox';
import NetworkInitForm from './NetworkInitForm';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { HeaderText } from './Text';
import useProtect from '../hooks/useProtect';
import useProtectedState from '../hooks/useProtectedState';

const PrepareNetworkForm = withRouter(
  ({
    router: {
      isReady,
      query: { host_uuid: queryHostUUID },
    },
  }) => {
    const { protect } = useProtect();

    const [dataHostDetail, setHostDetail] = useProtectedState<
      APIHostDetail | undefined
    >(undefined, protect);
    const [fatalErrorMessage, setFatalErrorMessage] = useProtectedState<
      Message | undefined
    >(undefined, protect);
    const [isLoading, setIsLoading] = useProtectedState<boolean>(true, protect);

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

    useEffect(() => {
      if (isReady) {
        if (queryHostUUID) {
          api
            .get<APIHostDetail>(
              `/host/${
                queryHostUUID instanceof Array
                  ? queryHostUUID[0]
                  : queryHostUUID
              }`,
            )
            .then(({ data }) => {
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
              setIsLoading(false);
            });
        } else if (!fatalErrorMessage) {
          setFatalErrorMessage({
            children: `No host UUID provided; cannot continue.`,
            type: 'error',
          });

          setIsLoading(false);
        }
      }
    }, [
      fatalErrorMessage,
      isReady,
      queryHostUUID,
      setFatalErrorMessage,
      setHostDetail,
      setIsLoading,
    ]);

    return <Panel>{contentElement}</Panel>;
  },
);

export default PrepareNetworkForm;
