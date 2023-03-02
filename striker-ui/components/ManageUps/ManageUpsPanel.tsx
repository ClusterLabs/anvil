import {
  FC,
  FormEventHandler,
  useCallback,
  useMemo,
  useRef,
  useState,
} from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import AddUpsInputGroup, { INPUT_ID_UPS_TYPE_ID } from './AddUpsInputGroup';
import api from '../../lib/api';
import { INPUT_ID_UPS_IP, INPUT_ID_UPS_NAME } from './CommonUpsInputGroup';
import ConfirmDialog from '../ConfirmDialog';
import EditUpsInputGroup, { INPUT_ID_UPS_UUID } from './EditUpsInputGroup';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import { Panel, PanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { BodyText, HeaderText, InlineMonoText, MonoText } from '../Text';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useIsFirstRender from '../../hooks/useIsFirstRender';
import useProtectedState from '../../hooks/useProtectedState';

type UpsFormData = {
  upsAgent: string;
  upsBrand: string;
  upsIPAddress: string;
  upsName: string;
  upsTypeId: string;
  upsUUID: string;
};

const getUpsFormData = (
  upsTemplate: APIUpsTemplate,
  ...[{ target }]: Parameters<FormEventHandler<HTMLDivElement>>
): UpsFormData => {
  const { elements } = target as HTMLFormElement;

  const { value: upsName } = elements.namedItem(
    INPUT_ID_UPS_NAME,
  ) as HTMLInputElement;
  const { value: upsIPAddress } = elements.namedItem(
    INPUT_ID_UPS_IP,
  ) as HTMLInputElement;

  const inputUpsTypeId = elements.namedItem(INPUT_ID_UPS_TYPE_ID);

  let upsAgent = '';
  let upsBrand = '';
  let upsTypeId = '';

  if (inputUpsTypeId) {
    ({ value: upsTypeId } = inputUpsTypeId as HTMLInputElement);
    ({ agent: upsAgent, brand: upsBrand } = upsTemplate[upsTypeId]);
  }

  const inputUpsUUID = elements.namedItem(INPUT_ID_UPS_UUID);

  let upsUUID = '';

  if (inputUpsUUID) {
    ({ value: upsUUID } = inputUpsUUID as HTMLInputElement);
  }

  return { upsAgent, upsBrand, upsIPAddress, upsName, upsTypeId, upsUUID };
};

const buildConfirmUpsFormData = ({
  upsBrand,
  upsIPAddress,
  upsName,
  upsUUID,
}: UpsFormData) => {
  const listItems: Record<string, { label: string; value: string }> = {
    'ups-brand': { label: 'Brand', value: upsBrand },
    'ups-name': { label: 'Host name', value: upsName },
    'ups-ip-address': { label: 'IP address', value: upsIPAddress },
  };

  return (
    <List
      listItems={listItems}
      listItemProps={{ sx: { padding: 0 } }}
      renderListItem={(part, { label, value }) => (
        <FlexBox fullWidth growFirst key={`confirm-ups-${upsUUID}-${part}`} row>
          <BodyText>{label}</BodyText>
          <MonoText>{value}</MonoText>
        </FlexBox>
      )}
    />
  );
};

const ManageUpsPanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const formDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();
  const [formDialogProps, setFormDialogProps] = useConfirmDialogProps();
  const [isEditUpses, setIsEditUpses] = useState<boolean>(false);
  const [isLoadingUpsTemplate, setIsLoadingUpsTemplate] =
    useProtectedState<boolean>(true);
  const [upsTemplate, setUpsTemplate] = useProtectedState<
    APIUpsTemplate | undefined
  >(undefined);

  const { data: upsOverviews, isLoading: isUpsOverviewLoading } =
    periodicFetch<APIUpsOverview>(`${API_BASE_URL}/ups`, {
      refreshInterval: 60000,
    });

  const buildEditUpsFormDialogProps = useCallback<
    (args: APIUpsOverview[string]) => ConfirmDialogProps
  >(
    ({ upsAgent, upsIPAddress, upsName, upsUUID }) => {
      // Determine the type of existing UPS based on its scan agent.
      // TODO: should identity an existing UPS's type in the DB.
      const upsTypeId: string =
        Object.entries(upsTemplate ?? {}).find(
          ([, { agent }]) => upsAgent === agent,
        )?.[0] ?? '';

      return {
        actionProceedText: 'Update',
        content: (
          <EditUpsInputGroup
            previous={{
              upsIPAddress,
              upsName,
              upsTypeId,
            }}
            upsTemplate={upsTemplate}
            upsUUID={upsUUID}
          />
        ),
        onSubmitAppend: (event) => {
          if (!upsTemplate) {
            return;
          }

          const editData = getUpsFormData(upsTemplate, event);
          const { upsName: newUpsName } = editData;

          setConfirmDialogProps({
            actionProceedText: 'Update',
            content: buildConfirmUpsFormData(editData),
            titleText: (
              <HeaderText>
                Update{' '}
                <InlineMonoText fontSize="inherit">{newUpsName}</InlineMonoText>{' '}
                with the following data?
              </HeaderText>
            ),
          });

          confirmDialogRef.current.setOpen?.call(null, true);
        },
        titleText: (
          <HeaderText>
            Update UPS{' '}
            <InlineMonoText fontSize="inherit">{upsName}</InlineMonoText>
          </HeaderText>
        ),
      };
    },
    [setConfirmDialogProps, upsTemplate],
  );

  const addUpsFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Add',
      content: <AddUpsInputGroup upsTemplate={upsTemplate} />,
      onSubmitAppend: (event) => {
        if (!upsTemplate) {
          return;
        }

        const addData = getUpsFormData(upsTemplate, event);
        const { upsBrand } = addData;

        setConfirmDialogProps({
          actionProceedText: 'Add',
          content: buildConfirmUpsFormData(addData),
          titleText: (
            <HeaderText>
              Add a{' '}
              <InlineMonoText fontSize="inherit">{upsBrand}</InlineMonoText> UPS
              with the following data?
            </HeaderText>
          ),
        });

        confirmDialogRef.current.setOpen?.call(null, true);
      },
      titleText: 'Add a UPS',
    }),
    [setConfirmDialogProps, upsTemplate],
  );

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditUpses}
        edit={isEditUpses}
        header
        listEmpty="No Ups(es) registered."
        listItems={upsOverviews}
        onAdd={() => {
          setFormDialogProps(addUpsFormDialogProps);
          formDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditUpses((previous) => !previous);
        }}
        onItemClick={(value) => {
          setFormDialogProps(buildEditUpsFormDialogProps(value));
          formDialogRef.current.setOpen?.call(null, true);
        }}
        renderListItem={(upsUUID, { upsAgent, upsIPAddress, upsName }) => (
          <FlexBox fullWidth row>
            <BodyText>{upsName}</BodyText>
            <BodyText>agent=&quot;{upsAgent}&quot;</BodyText>
            <BodyText>ip=&quot;{upsIPAddress}&quot;</BodyText>
          </FlexBox>
        )}
      />
    ),
    [
      addUpsFormDialogProps,
      buildEditUpsFormDialogProps,
      isEditUpses,
      setFormDialogProps,
      upsOverviews,
    ],
  );
  const panelContent = useMemo(
    () =>
      isLoadingUpsTemplate || isUpsOverviewLoading ? <Spinner /> : listElement,
    [isLoadingUpsTemplate, isUpsOverviewLoading, listElement],
  );

  if (isFirstRender) {
    api
      .get<APIUpsTemplate>('/ups/template')
      .then(({ data }) => {
        setUpsTemplate(data);
      })
      .catch((error) => {
        handleAPIError(error);
      })
      .finally(() => {
        setIsLoadingUpsTemplate(false);
      });
  }

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage UPSes</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <FormDialog {...formDialogProps} ref={formDialogRef} />
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ManageUpsPanel;
