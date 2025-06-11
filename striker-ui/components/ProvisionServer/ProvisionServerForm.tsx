import { Box as MuiBox, createFilterOptions, Grid } from '@mui/material';
import { DataSize, dSize, dSizeStr } from 'format-data-size';
import { isEqual } from 'lodash';
import { useCallback, useContext, useEffect, useMemo, useState } from 'react';

import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import Autocomplete from '../Autocomplete';
import { DialogContext } from '../Dialog';
import handleAPIError from '../../lib/handleAPIError';
import MaxButton from './MaxButton';
import MessageBox from '../MessageBox';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import ProvisionServerDiskForm from './ProvisionServerDiskForm';
import ProvisionServerExistingList from './ProvisionServerExistingList';
import ProvisionServerSummary from './ProvisionServerSummary';
import { buildProvisionServerSchema } from './schemas';
import { BodyText, SmallText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFormikUtils from '../../hooks/useFormikUtils';

const ProvisionServerForm: React.FC<ProvisionServerFormProps> = (props) => {
  const { lsos, resources } = props;

  const dialog = useContext(DialogContext);

  const files = useMemo(
    () => ({
      uuids: Object.keys(resources.files),
    }),
    [resources.files],
  );

  const nodes = useMemo(
    () => ({
      uuids: Object.keys(resources.nodes),
      values: Object.values(resources.nodes),
    }),
    [resources.nodes],
  );

  const oses = useMemo(
    () => ({
      keys: Object.keys(lsos).sort((a, b) =>
        b.localeCompare(a, undefined, {
          numeric: true,
        }),
      ),
    }),
    [lsos],
  );

  const storageGroups = useMemo(
    () => ({
      uuids: Object.keys(resources.storageGroups),
      values: Object.values(resources.storageGroups),
    }),
    [resources.storageGroups],
  );

  const groups = useMemo(
    () =>
      nodes.values.reduce<ProvisionServerScopeGroup[]>((previous, node) => {
        node.storageGroups.forEach((sgUuid) => {
          previous.push({
            node: node.uuid,
            storageGroup: sgUuid,
          });
        });

        return previous;
      }, []),
    [nodes.values],
  );

  const [scope, setScope] = useState<ProvisionServerScopeGroup[]>(groups);

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogProps,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
  } = useConfirmDialog();

  const validationSchema = useMemo(
    () => buildProvisionServerSchema(scope, resources, lsos),
    [lsos, resources, scope],
  );

  const formikUtils = useFormikUtils<ProvisionServerFormikValues>({
    initialValues: {
      cpu: {
        cores: '2',
      },
      disks: {
        '0': {
          size: {
            unit: 'GiB',
            value: '20',
          },
          storageGroup: null,
        },
      },
      driver: null,
      install: null,
      memory: {
        unit: 'GiB',
        value: '1',
      },
      name: '',
      node: null,
      os: null,
    },
    onSubmit: (values, { setSubmitting }) => {
      setConfirmDialogProps({
        actionProceedText: 'Provision',
        content: (
          <ProvisionServerSummary
            lsos={lsos}
            resources={resources}
            values={values}
          />
        ),
        onCancelAppend: () => setSubmitting(false),
        onProceedAppend: () => {
          setConfirmDialogLoading(true);

          const memoryBytes = dSize(values.memory.value, {
            fromUnit: values.memory.unit,
            precision: 0,
            toUnit: 'B',
          });

          if (!memoryBytes) {
            finishConfirm('Error', {
              children: <>Failed to convert memory to bytes.</>,
            });

            return;
          }

          let virtualDisks: APIProvisionServerRequestBody['virtualDisks'];

          try {
            virtualDisks = Object.keys(values.disks).map((id) => {
              const { [id]: disk } = values.disks;

              const { size, storageGroup } = disk;

              const sizeBytes = dSize(size.value, {
                fromUnit: size.unit,
                precision: 0,
                toUnit: 'B',
              });

              if (!sizeBytes) {
                throw new Error(`Failed to convert disk ${id} size to bytes.`);
              }

              return {
                storageSize: sizeBytes.value,
                storageGroupUUID: storageGroup as string,
              };
            });
          } catch (error) {
            finishConfirm('Error', {
              children: String(error),
            });

            return;
          }

          const body: APIProvisionServerRequestBody = {
            serverName: values.name,
            cpuCores: Number(values.cpu.cores as string),
            memory: memoryBytes.value,
            virtualDisks,
            installISOFileUUID: values.install as string,
            driverISOFileUUID: values.driver ? values.driver : '',
            anvilUUID: values.node as string,
            optimizeForOS: values.os as string,
          };

          api
            .post('/server', body)
            .then(() => {
              finishConfirm('Success', {
                children: <>Provision server job registered.</>,
              });

              dialog?.setOpen(false);
            })
            .catch((error) => {
              const emsg = handleAPIError(error);

              emsg.children = (
                <>Failed to start provision server job. {emsg.children}</>
              );

              finishConfirm('Error', emsg);

              setSubmitting(false);
            });
        },
        titleText: `Provision ${values.name}?`,
      });

      setConfirmDialogOpen(true);
    },
    validationSchema,
  });

  const {
    changeFieldValue,
    disabledSubmit,
    formik,
    formikErrors,
    getFieldChanged,
    handleChange,
  } = formikUtils;

  const chains = useMemo(
    () => ({
      cpu: {
        cores: 'cpu.cores',
      },
      driver: 'driver',
      install: 'install',
      memory: {
        unit: 'memory.unit',
        value: 'memory.value',
      },
      name: 'name',
      node: 'node',
      os: 'os',
    }),
    [],
  );

  const disks = useMemo(
    () => ({
      ids: Object.keys(formik.values.disks),
    }),
    [formik.values.disks],
  );

  useEffect(() => {
    let rescope = [...groups];

    // Lock the scope to the selected node
    if (formik.values.node) {
      rescope = rescope.filter((group) => group.node === formik.values.node);
    }

    const cpuCores = Number(formik.values.cpu.cores);

    // Limit the scope to nodes with sufficient CPU cores
    if (Number.isSafeInteger(cpuCores)) {
      rescope = rescope.filter((group) => {
        const { [group.node]: node } = resources.nodes;

        return node.cpu.cores.total >= cpuCores;
      });
    }

    const memoryBytes = dSize(formik.values.memory.value, {
      fromUnit: formik.values.memory.unit,
      precision: 0,
      toUnit: 'B',
    });

    // Limit the scope to nodes with sufficient memory
    if (memoryBytes) {
      const bytes = BigInt(memoryBytes.value);

      rescope = rescope.filter((group) => {
        const { [group.node]: node } = resources.nodes;

        return node.memory.available >= bytes;
      });
    }

    disks.ids.forEach((id) => {
      const { size, storageGroup: sgUuid } = formik.values.disks[id];

      // When there's a storage group, limit the scope to nodes that owns the
      // storage group
      if (sgUuid) {
        const { [sgUuid]: sg } = resources.storageGroups;

        rescope = rescope.filter((group) => group.node === sg.node);
      }

      const diskBytes = dSize(size.value, {
        fromUnit: size.unit,
        precision: 0,
        toUnit: 'B',
      });

      // Limit the scope to nodes with sufficient storage
      if (diskBytes) {
        const bytes = BigInt(diskBytes.value);

        rescope = rescope.filter((group) => {
          const { [group.storageGroup]: sg } = resources.storageGroups;

          return sg.usage.free >= bytes;
        });
      }
    });

    if (isEqual(scope, rescope)) {
      return;
    }

    setScope(rescope);
  }, [
    disks.ids,
    formik.values.cpu.cores,
    formik.values.disks,
    formik.values.memory.unit,
    formik.values.memory.value,
    formik.values.node,
    groups,
    resources.nodes,
    resources.storageGroups,
    scope,
  ]);

  // Auto fill-in fields where there are only 1 option
  useEffect(() => {
    // When there's only 1 ISO, select it as the install ISO
    if (files.uuids.length === 1) {
      const [only] = files.uuids;

      const changed = getFieldChanged(chains.install);

      if ([changed, formik.values.install].every((value) => !value)) {
        formik.setFieldValue(chains.install, only, true);
      }
    }

    // Get distinct UUIDs from the scope
    const distinct = scope.reduce<{
      nodes: Record<string, string>;
      storageGroups: Record<string, string>;
    }>(
      (previous, group) => {
        const { node: nodeUuid, storageGroup: sgUuid } = group;

        previous.nodes[nodeUuid] = nodeUuid;
        previous.storageGroups[sgUuid] = sgUuid;

        return previous;
      },
      {
        nodes: {},
        storageGroups: {},
      },
    );

    const distinctNodes = Object.keys(distinct.nodes);

    // When there's only 1 node within the scope, select it
    if (distinctNodes.length === 1) {
      const [only] = distinctNodes;

      const changed = getFieldChanged(chains.node);

      if ([changed, formik.values.node].every((value) => !value)) {
        formik.setFieldValue(chains.node, only, true);
      }
    }

    const distinctSgs = Object.keys(distinct.storageGroups);

    // When there's only 1 storage group within the scope, select it for all
    // disks
    if (distinctSgs.length === 1) {
      const [only] = distinctSgs;

      disks.ids.forEach((id) => {
        const field = `disks.${id}.storageGroup`;

        const changed = getFieldChanged(field);

        if (
          [changed, formik.values.disks[id].storageGroup].every(
            (value) => !value,
          )
        ) {
          formik.setFieldValue(field, only, true);
        }
      });
    }
  }, [
    chains.install,
    chains.node,
    disks.ids,
    files.uuids,
    formik,
    getFieldChanged,
    scope,
  ]);

  const maxAvailableMemory = useMemo(
    () =>
      scope.reduce<bigint>((previous, group) => {
        const { node: uuid } = group;

        const node = resources.nodes[uuid];

        return node.memory.available > previous
          ? node.memory.available
          : previous;
      }, BigInt(0)),
    [resources.nodes, scope],
  );

  const maxAvailableMemoryReadable = useMemo<DataSize & { str: string }>(() => {
    const size = dSize(maxAvailableMemory, {
      toUnit: formik.values.memory.unit,
    });

    if (!size) {
      return {
        str: 'unknown',
        unit: 'B',
        value: '0',
      };
    }

    return {
      ...size,
      str: `${size.value} ${size.unit}`,
    };
  }, [formik.values.memory.unit, maxAvailableMemory]);

  const cpuCoresOptions = useMemo<readonly string[]>(() => {
    const max = nodes.values.reduce<number>(
      (previous, node) => Math.max(previous, node.cpu.cores.total),
      0,
    );

    return Array.from({ length: max }, (value, key) => String(key + 1));
  }, [nodes]);

  const getFileOptionLabel = useCallback(
    (uuid: string) => {
      const { [uuid]: file } = resources.files;

      return file.name;
    },
    [resources.files],
  );

  const filterFileOptions = useMemo(
    () =>
      createFilterOptions<string>({
        ignoreCase: true,
        stringify: (uuid) => {
          const { [uuid]: file } = resources.files;

          return file.name;
        },
      }),
    [resources.files],
  );

  const renderFileOption = useCallback(
    (
      field: string,
      optionProps: React.HTMLAttributes<HTMLLIElement>,
      uuid: string,
    ): React.ReactNode => {
      const { [uuid]: file } = resources.files;

      const locations = Object.values(file.locations);

      const syncing = locations.reduce<ProvisionServerResourceSubnode[]>(
        (previous, location) => {
          const { ready, subnode: id } = location;

          const { [id]: subnode } = resources.subnodes;

          if (ready || !subnode) {
            return previous;
          }

          previous.push(subnode);

          return previous;
        },
        [],
      );

      const status = syncing.length ? (
        <>Syncing to {syncing.map<string>(({ short }) => short).join(', ')}</>
      ) : (
        <>Ready</>
      );

      return (
        <li {...optionProps} key={`${field}-op-${uuid}`}>
          <MuiBox width="100%">
            <BodyText inheritColour noWrap>
              {file.name}
            </BodyText>
            <SmallText inheritColour noWrap>
              {status}
            </SmallText>
          </MuiBox>
        </li>
      );
    },
    [resources.files, resources.subnodes],
  );

  const resourceMessages = useMemo(() => {
    const messages: Messages = {};

    [
      ['file', files.uuids.length],
      ['node', nodes.uuids.length],
      ['storage group', storageGroups.uuids.length],
    ].reduce<Messages>((previous, [resource, count]) => {
      if (count) {
        return previous;
      }

      previous[resource] = {
        children: (
          <>
            No {resource} available yet. It will appear shortly after its
            creation.
          </>
        ),
      };

      return previous;
    }, messages);

    return {
      entries: Object.entries(messages),
      messages,
    };
  }, [files.uuids.length, nodes.uuids.length, storageGroups.uuids.length]);

  if (resourceMessages.entries.length) {
    const { entries } = resourceMessages;

    return (
      <Grid container spacing="1em">
        {entries.map<React.ReactNode>(([key, message]) => (
          <Grid item key={`${key}-message`} width="100%">
            <MessageBox type="warning" {...message} />
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <>
      <Grid container spacing="1em">
        <Grid item width="16em">
          <ProvisionServerExistingList resources={resources} />
        </Grid>
        <Grid item xs>
          <Grid
            component="form"
            container
            onSubmit={(event) => {
              event.preventDefault();

              formik.handleSubmit(event);
            }}
            spacing="1em"
          >
            <Grid item width="100%">
              <UncontrolledInput
                input={
                  <OutlinedInputWithLabel
                    id={chains.name}
                    label="Server name"
                    name={chains.name}
                    onChange={handleChange}
                    required
                    value={formik.values.name}
                  />
                }
              />
            </Grid>
            <Grid item width="100%">
              <Autocomplete
                getOptionDisabled={(value) => {
                  const count = Number(value);

                  return scope.every((group) => {
                    const { [group.node]: node } = resources.nodes;

                    return node.cpu.cores.total < count;
                  });
                }}
                id={chains.cpu.cores}
                label="CPU cores"
                noOptionsText="No node has the requested cores"
                onChange={(event, value) => {
                  changeFieldValue(chains.cpu.cores, value, true);
                }}
                openOnFocus
                options={cpuCoresOptions}
                required
                value={formik.values.cpu.cores}
              />
            </Grid>
            <Grid item width="100%">
              <UncontrolledInput
                input={
                  <OutlinedLabeledInputWithSelect
                    id="memory"
                    inputWithLabelProps={{
                      id: chains.memory.value,
                      inputProps: {
                        endAdornment: (
                          <MaxButton
                            onClick={() => {
                              changeFieldValue(
                                chains.memory.value,
                                maxAvailableMemoryReadable.value,
                                true,
                              );
                            }}
                          >
                            {maxAvailableMemoryReadable.str}
                          </MaxButton>
                        ),
                      },
                      name: chains.memory.value,
                      required: true,
                    }}
                    label="Memory"
                    onChange={handleChange}
                    selectItems={DSIZE_SELECT_ITEMS}
                    selectWithLabelProps={{
                      id: chains.memory.unit,
                      name: chains.memory.unit,
                      onChange: formik.handleChange,
                      value: formik.values.memory.unit,
                    }}
                    value={formik.values.memory.value}
                  />
                }
              />
            </Grid>
            {disks.ids.map<React.ReactNode>((diskId) => (
              <Grid item key={`disk-${diskId}-form`} width="100%">
                <ProvisionServerDiskForm
                  formikUtils={formikUtils}
                  id={diskId}
                  resources={resources}
                  scope={scope}
                />
              </Grid>
            ))}
            <Grid item width="100%">
              <Autocomplete
                filterOptions={filterFileOptions}
                getOptionDisabled={(uuid) => uuid === formik.values.driver}
                getOptionLabel={getFileOptionLabel}
                id={chains.install}
                label="Install ISO"
                noOptionsText="No matching ISO"
                onChange={(event, value) => {
                  changeFieldValue(chains.install, value, true);
                }}
                openOnFocus
                options={files.uuids}
                renderOption={(optionProps, uuid) =>
                  renderFileOption(chains.install, optionProps, uuid)
                }
                required
                value={formik.values.install}
              />
            </Grid>
            <Grid item width="100%">
              <Autocomplete
                filterOptions={filterFileOptions}
                getOptionDisabled={(uuid) => uuid === formik.values.install}
                getOptionLabel={getFileOptionLabel}
                id={chains.driver}
                label="Driver ISO"
                noOptionsText="No matching ISO"
                onChange={(event, value) => {
                  changeFieldValue(chains.driver, value, true);
                }}
                openOnFocus
                options={files.uuids}
                renderOption={(optionProps, uuid) =>
                  renderFileOption(chains.driver, optionProps, uuid)
                }
                value={formik.values.driver}
              />
            </Grid>
            <Grid item width="100%">
              <Autocomplete
                filterOptions={createFilterOptions<string>({
                  ignoreCase: true,
                  stringify: (uuid) => {
                    const { [uuid]: node } = resources.nodes;

                    return `${node.name}\n${node.description}`;
                  },
                })}
                getOptionDisabled={(uuid) =>
                  scope.every((group) => group.node !== uuid)
                }
                getOptionLabel={(uuid) => {
                  const { [uuid]: node } = resources.nodes;

                  return node.name;
                }}
                id={chains.node}
                label="Node"
                noOptionsText="No matching node"
                onChange={(event, value) => {
                  changeFieldValue(chains.node, value, true);
                }}
                openOnFocus
                options={nodes.uuids}
                renderOption={(optionProps, uuid) => {
                  const { [uuid]: node } = resources.nodes;

                  return (
                    <li {...optionProps} key={`node-op-${uuid}`}>
                      <Grid alignItems="center" container>
                        <Grid item width="70%">
                          <BodyText inheritColour noWrap>
                            {node.name}
                          </BodyText>
                          <SmallText inheritColour noWrap>
                            {node.description}
                          </SmallText>
                        </Grid>
                        <Grid item width="30%">
                          <BodyText inheritColour noWrap>
                            CPU: {node.cpu.cores.total} cores
                          </BodyText>
                          <BodyText inheritColour noWrap>
                            Memory:{' '}
                            {dSizeStr(node.memory.available, {
                              toUnit: 'ibyte',
                            })}
                          </BodyText>
                        </Grid>
                      </Grid>
                    </li>
                  );
                }}
                required
                value={formik.values.node}
              />
            </Grid>
            <Grid item width="100%">
              <Autocomplete
                filterOptions={createFilterOptions<string>({
                  ignoreCase: true,
                  stringify: (osKey) => {
                    const { [osKey]: os } = lsos;

                    return `${osKey}\n${os}`;
                  },
                })}
                getOptionLabel={(osKey) => {
                  const { [osKey]: os } = lsos;

                  return os;
                }}
                id={chains.os}
                label="Optimize for OS"
                noOptionsText="No OS that matches exactly; try finding a close match"
                onChange={(event, value) => {
                  changeFieldValue(chains.os, value, true);
                }}
                openOnFocus
                options={oses.keys}
                renderOption={(optionProps, osKey) => {
                  const { [osKey]: os } = lsos;

                  return (
                    <li {...optionProps} key={`os-op-${osKey}`}>
                      <MuiBox width="100%">
                        <BodyText inheritColour noWrap>
                          {os}
                        </BodyText>
                        <SmallText inheritColour noWrap>
                          {osKey}
                        </SmallText>
                      </MuiBox>
                    </li>
                  );
                }}
                required
                value={formik.values.os}
              />
            </Grid>
            <Grid item width="100%">
              <MessageGroup count={1} messages={formikErrors} />
            </Grid>
            <Grid item width="100%">
              <ActionGroup
                actions={[
                  {
                    background: 'blue',
                    children: 'Provision',
                    disabled: disabledSubmit,
                    type: 'submit',
                  },
                ]}
              />
            </Grid>
          </Grid>
        </Grid>
      </Grid>
      {confirmDialog}
    </>
  );
};

export default ProvisionServerForm;
