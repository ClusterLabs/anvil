import { useRouter } from 'next/router';
import { FC, useCallback, useEffect, useMemo, useRef, useState } from 'react';

import api from '../lib/api';
import ConfirmDialog from './ConfirmDialog';
import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import FormSummary from './FormSummary';
import getQueryParam from '../lib/getQueryParam';
import handleAPIError from '../lib/handleAPIError';
import InputWithRef from './InputWithRef';
import MessageBox, { Message } from './MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from './MessageGroup';
import NetworkInitForm, {
  NetworkInitFormForwardedRefContent,
} from './NetworkInitForm';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import SwitchWithLabel from './SwitchWithLabel';
import { buildPeacefulStringTestBatch } from '../lib/test_input';
import { HeaderText } from './Text';
import useConfirmDialogProps from '../hooks/useConfirmDialogProps';
import useFormUtils from '../hooks/useFormUtils';

const INPUT_ID_PREP_NET_HOST_NAME = 'prepare-network-host-name-input';

const INPUT_GROUP_ID_PREP_NET_NETCONF = 'prepare-network-netconf-input-group';

const INPUT_LABEL_PREP_NET_HOST_NAME = 'Host name';

const getFormData = (
  {
    netconf,
  }: {
    netconf: NetworkInitFormForwardedRefContent;
  },
  ...[{ target }]: DivFormEventHandlerParameters
) => {
  const { elements } = target as HTMLFormElement;

  const { value: hostName } = elements.namedItem(
    INPUT_ID_PREP_NET_HOST_NAME,
  ) as HTMLInputElement;

  const data = {
    hostName,
    ...netconf.get?.call(null),
  };

  return data;
};

const toFormEntries = (body: ReturnType<typeof getFormData>): FormEntries => {
  const { networks: nets = [], ...rest } = body;

  const networks = nets.reduce<FormEntries>((previous, network) => {
    const {
      interfaces: ifaces,
      ipAddress,
      name = '',
      type,
      typeCount,
      subnetMask,
    } = network;
    const networkId = `${type}${typeCount}`;

    const interfaces = ifaces.reduce<FormEntries>((pIfaces, iface, index) => {
      if (iface) {
        const { networkInterfaceName } = iface;
        const linkNumber = index + 1;

        pIfaces[`link${linkNumber}`] = networkInterfaceName;
      }

      return pIfaces;
    }, {});

    previous[networkId] = {
      name,
      network: `${ipAddress}/${subnetMask}`,
      ...interfaces,
    };

    return previous;
  }, {});

  return { ...rest, networks };
};

const PrepareNetworkForm: FC<PrepareNetworkFormProps> = ({
  expectUUID: isExpectExternalHostUUID = false,
  hostUUID,
}) => {
  const {
    isReady,
    query: { host_uuid: queryHostUUID },
  } = useRouter();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const netconfFormRef = useRef<NetworkInitFormForwardedRefContent>({});

  const generalInputMessageGroupRef = useRef<MessageGroupForwardedRefContent>(
    {},
  );

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();

  const [hostDetail, setHostDetail] = useState<APIHostDetail | undefined>();
  const [fatalErrorMessage, setFatalErrorMessage] = useState<
    Message | undefined
  >();
  const [isLoadingHostDetail, setIsLoadingHostDetail] = useState<boolean>(true);
  const [previousHostUUID, setPreviousHostUUID] = useState<
    string | undefined
  >();

  const [mini, setMini] = useState<boolean>(false);

  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    isFormInvalid,
    setMessage,
    setValidity,
    submitForm,
  } = useFormUtils(
    [INPUT_ID_PREP_NET_HOST_NAME, INPUT_GROUP_ID_PREP_NET_NETCONF],
    generalInputMessageGroupRef,
  );

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
  const netconfForm = useMemo(
    () => (
      <NetworkInitForm
        expectHostDetail
        hostDetail={hostDetail}
        ref={netconfFormRef}
        mini={mini}
        toggleSubmitDisabled={(valid) => {
          setValidity(INPUT_GROUP_ID_PREP_NET_NETCONF, valid);
        }}
      />
    ),
    [hostDetail, mini, setValidity],
  );
  const generalInputMessageArea = useMemo(
    () => (
      <MessageGroup
        count={1}
        defaultMessageType="warning"
        ref={generalInputMessageGroupRef}
      />
    ),
    [],
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
          <FlexBox
            component="form"
            onSubmit={(...args) => {
              const [event] = args;

              event.preventDefault();

              const body = getFormData(
                { netconf: netconfFormRef.current },
                ...args,
              );

              setConfirmDialogProps({
                actionProceedText: 'Prepare',
                content: (
                  <FormSummary
                    entries={toFormEntries(body)}
                    getEntryLabel={({ cap, key }) =>
                      /^(dns|[a-z]+n\d+)/.test(key)
                        ? key.toUpperCase()
                        : cap(key)
                    }
                  />
                ),
                onProceedAppend: () => {
                  submitForm({
                    body,
                    getErrorMsg: (parentMsg) => (
                      <>Failed to prepare network. {parentMsg}</>
                    ),
                    method: 'put',
                    setMsg: netconfFormRef?.current?.setMessage,
                    successMsg: `Initiated prepare network on ${hostDetail?.shortHostName}`,
                    url: `/host/${hostUUID}?handler=subnode-network`,
                  });
                },
                titleText: `Prepare ${hostDetail?.shortHostName} network?`,
              });

              confirmDialogRef.current.setOpen?.call(null, true);
            }}
          >
            <FlexBox sm="row" xs="column">
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{ sx: { maxWidth: '20em' } }}
                    id={INPUT_ID_PREP_NET_HOST_NAME}
                    label={INPUT_LABEL_PREP_NET_HOST_NAME}
                    value={hostDetail?.hostName}
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  INPUT_LABEL_PREP_NET_HOST_NAME,
                  () => {
                    setMessage(INPUT_ID_PREP_NET_HOST_NAME);
                  },
                  {
                    onFinishBatch: buildFinishInputTestBatchFunction(
                      INPUT_ID_PREP_NET_HOST_NAME,
                    ),
                  },
                  (message) => {
                    setMessage(INPUT_ID_PREP_NET_HOST_NAME, {
                      children: message,
                    });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(
                  INPUT_ID_PREP_NET_HOST_NAME,
                )}
                required
              />
              <SwitchWithLabel
                checked={mini}
                label="Minimal"
                onChange={() => setMini((previous) => !previous)}
              />
            </FlexBox>
            {generalInputMessageArea}
            {netconfForm}
            <FlexBox row justifyContent="flex-end">
              <ContainedButton disabled={isFormInvalid} type="submit">
                Prepare network
              </ContainedButton>
            </FlexBox>
          </FlexBox>
        </>
      );
    }

    return result;
  }, [
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    fatalErrorMessage,
    generalInputMessageArea,
    hostDetail?.hostName,
    hostDetail?.shortHostName,
    hostUUID,
    isFormInvalid,
    isLoadingHostDetail,
    mini,
    netconfForm,
    panelHeaderElement,
    setConfirmDialogProps,
    setMessage,
    submitForm,
  ]);

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

  return (
    <>
      <Panel>{contentElement}</Panel>
      <ConfirmDialog
        closeOnProceed
        scrollContent
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default PrepareNetworkForm;
