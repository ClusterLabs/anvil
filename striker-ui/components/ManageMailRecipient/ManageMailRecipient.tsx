import { Grid2 as MuiGrid } from '@mui/material';
import { useMemo, useState } from 'react';

import AddMailRecipientForm from './AddMailRecipientForm';
import alertLevels from './alertLevels';
import { toAnvilOverviewList } from '../../lib/api_converters';
import CrudList from '../CrudList';
import EditMailRecipientForm from './EditMailRecipientForm';
import { BodyText } from '../Text';
import useActiveFetch from '../../hooks/useActiveFetch';
import useFetch from '../../hooks/useFetch';

const ManageMailRecipient: React.FC = () => {
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
          const nodeTarget: AlertOverrideTarget = {
            description: node.description,
            name: node.name,
            node: node.uuid,
            subnodes: [],
            type: 'node',
            uuid: node.uuid,
          };

          const subnodeTargets = Object.values(node.hosts)
            .sort((a, b) => a.name.localeCompare(b.name))
            .reduce<AlertOverrideTarget[]>((previous, subnode) => {
              if (subnode.type === 'dr') return previous;

              previous.push({
                name: subnode.name,
                node: node.uuid,
                type: 'subnode',
                uuid: subnode.uuid,
              });

              nodeTarget.subnodes?.push(subnode.uuid);

              return previous;
            }, []);

          // Append the options in sequence: node followed by its subnode(s).
          options.push(nodeTarget, ...subnodeTargets);

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
    if (!nodes || !alertOverrides) return undefined;

    /**
     * Group alert override rules based on node UUID. The groups will be used
     * for comparison to see whether the subnodes are assigned the same alert
     * level.
     *
     * If subnodes have the same level, they will be consolidated into a single
     * target for display. Otherwise, every subnode will get its own visual.
     */
    const groups = Object.values(alertOverrides).reduce<
      Record<string, APIAlertOverrideOverview[]>
    >((previous, override) => {
      const {
        node: { uuid: nodeUuid },
      } = override;

      if (previous[nodeUuid]) {
        previous[nodeUuid].push(override);
      } else {
        previous[nodeUuid] = [override];
      }

      return previous;
    }, {});

    return Object.entries(groups).reduce<AlertOverrideFormikValues>(
      (previous, pair) => {
        const [nodeUuid, overrides] = pair;
        const [firstOverride, ...restOverrides] = overrides;

        const sameLevel =
          overrides.length > 1 &&
          restOverrides.every(({ level }) => level === firstOverride.level);

        if (sameLevel) {
          const {
            0: { level },
          } = overrides;

          const { [nodeUuid]: node } = nodes;

          previous[nodeUuid] = {
            level,
            target: {
              description: node.description,
              name: node.name,
              node: node.uuid,
              subnodes: overrides.map<string>(({ subnode: { uuid } }) => uuid),
              type: 'node',
              uuid: node.uuid,
            },
            uuids: overrides.reduce<Record<string, string>>(
              (uuids, { subnode, uuid: overrideUuid }) => {
                uuids[overrideUuid] = subnode.uuid;

                return uuids;
              },
              {},
            ),
          };
        } else {
          overrides.forEach(({ level, node, subnode, uuid: overrideUuid }) => {
            previous[subnode.uuid] = {
              level,
              target: {
                name: subnode.name,
                node: node.uuid,
                type: 'subnode',
                uuid: subnode.uuid,
              },
              uuids: { [overrideUuid]: subnode.uuid },
            };
          });
        }

        return previous;
      },
      {},
    );
  }, [alertOverrides, nodes]);

  return (
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
      listEmpty="No mail recipient(s) found."
      onItemClick={(base, { args }) => {
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
      renderListItem={(uuid, { email, level, name }) => (
        <MuiGrid columnSpacing="1em" container width="100%">
          <MuiGrid size="grow">
            <BodyText edge="start" noWrap>
              {name}
            </BodyText>
            <BodyText edge="start" monospaced noWrap>
              {email}
            </BodyText>
          </MuiGrid>
          <MuiGrid textAlign="right">
            <BodyText edge="end">Alert level</BodyText>
            <BodyText edge="end" monospaced>
              {alertLevels[level].label}
            </BodyText>
          </MuiGrid>
        </MuiGrid>
      )}
    />
  );
};

export default ManageMailRecipient;
