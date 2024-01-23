import { FC, useMemo, useState } from 'react';

import AddMailRecipientForm from './AddMailRecipientForm';
import { toAnvilOverviewList } from '../../lib/api_converters';
import CrudList from '../CrudList';
import EditMailRecipientForm from './EditMailRecipientForm';
import { BodyText } from '../Text';
import useActiveFetch from '../../hooks/useActiveFetch';
import useFetch from '../../hooks/useFetch';

const ManageMailRecipient: FC = () => {
  const [alertOverrides, setAlertOverrides] = useState<
    APIAlertOverrideOverviewList | undefined
  >();

  const { altData: nodes, loading: loadingNodes } = useFetch<
    APIAnvilOverviewArray,
    APIAnvilOverviewList
  >('/anvil', { mod: toAnvilOverviewList });

  const alertOverrideTargetOptions = useMemo<AlertOverrideTarget[] | undefined>(
    () =>
      nodes &&
      Object.values(nodes)
        .sort((a, b) => a.name.localeCompare(b.name))
        .reduce<AlertOverrideTarget[]>((options, node) => {
          options.push({
            description: node.description,
            name: node.name,
            node: node.uuid,
            type: 'node',
            uuid: node.uuid,
          });

          Object.values(node.hosts)
            .sort((a, b) => a.name.localeCompare(b.name))
            .forEach((subnode) => {
              if (subnode.type === 'dr') return;

              options.push({
                name: subnode.name,
                node: node.uuid,
                type: 'subnode',
                uuid: subnode.uuid,
              });
            });

          return options;
        }, []),
    [nodes],
  );

  const { fetch: getAlertOverrides, loading: loadingAlertOverrides } =
    useActiveFetch<APIAlertOverrideOverviewList>({
      onData: (data) => setAlertOverrides(data),
      url: '/alert-override',
    });

  const formikAlertOverrides = useMemo<
    AlertOverrideFormikValues | undefined
  >(() => {
    if (!alertOverrides) return undefined;

    const groups: Record<string, number> = {};

    return Object.values(alertOverrides).reduce<AlertOverrideFormikValues>(
      (previous, value) => {
        const { level, node, subnode, uuid } = value;

        groups[node.uuid] = groups[node.uuid] ? groups[node.uuid] + 1 : 1;

        previous[uuid] = {
          level,
          target:
            groups[node.uuid] > 1
              ? {
                  name: node.name,
                  node: node.uuid,
                  type: 'node',
                  uuid: node.uuid,
                }
              : {
                  name: subnode.name,
                  node: node.uuid,
                  type: 'subnode',
                  uuid: subnode.uuid,
                },
          uuid,
        };

        return previous;
      },
      {},
    );
  }, [alertOverrides]);

  return (
    <>
      <CrudList<APIMailRecipientOverview, APIMailRecipientDetail>
        addHeader="Add mail recipient"
        editHeader={(entry) => `Update ${entry?.name}`}
        entriesUrl="/mail-recipient"
        getAddLoading={(previous) => previous || loadingNodes}
        getDeleteErrorMessage={({ children, ...rest }) => ({
          ...rest,
          children: <>Failed to delete mail recipient(s). {children}</>,
        })}
        getDeleteHeader={(count) =>
          `Delete the following ${count} mail recipient(s)?`
        }
        getDeleteSuccessMessage={() => ({
          children: <>Successfully deleted mail recipient(s).</>,
        })}
        getEditLoading={(previous) => previous || loadingAlertOverrides}
        onItemClick={(base, ...args) => {
          const [, mailRecipientUuid] = args;

          base(...args);

          getAlertOverrides(undefined, {
            params: { 'mail-recipient': mailRecipientUuid },
          });
        }}
        renderAddForm={(tools) =>
          alertOverrideTargetOptions && (
            <AddMailRecipientForm
              alertOverrideTargetOptions={alertOverrideTargetOptions}
              tools={tools}
            />
          )
        }
        renderDeleteItem={(mailRecipientList, { key }) => {
          const mr = mailRecipientList?.[key];

          return <BodyText>{mr?.name}</BodyText>;
        }}
        renderEditForm={(tools, mailRecipient) =>
          alertOverrideTargetOptions &&
          mailRecipient &&
          formikAlertOverrides && (
            <EditMailRecipientForm
              alertOverrideTargetOptions={alertOverrideTargetOptions}
              mailRecipientUuid={mailRecipient.uuid}
              previousFormikValues={{
                [mailRecipient.uuid]: {
                  alertOverrides: formikAlertOverrides,
                  ...mailRecipient,
                },
              }}
              tools={tools}
            />
          )
        }
        renderListItem={(uuid, { name }) => <BodyText>{name}</BodyText>}
      />
    </>
  );
};

export default ManageMailRecipient;
