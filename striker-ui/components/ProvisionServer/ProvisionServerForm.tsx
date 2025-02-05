import { Box, createFilterOptions, Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { useCallback, useMemo } from 'react';

import { DSIZE_SELECT_ITEMS } from '../../lib/consts/DSIZES';

import Autocomplete from '../Autocomplete';
import MessageBox from '../MessageBox';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import OutlinedLabeledInputWithSelect from '../OutlinedLabeledInputWithSelect';
import ProvisionServerDiskForm from './ProvisionServerDiskForm';
import { BodyText, SmallText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ProvisionServerForm: React.FC<ProvisionServerFormProps> = (props) => {
  const { lsos, resources } = props;

  const formikUtils = useFormikUtils<ProvisionServerFormikValues>({
    initialValues: {
      cpu: {
        cores: '2',
      },
      disks: {
        '0': {
          size: {
            unit: 'GiB',
            value: '1',
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
      setSubmitting(false);
    },
  });

  const { formik, formikErrors, handleChange } = formikUtils;

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

  const disks = useMemo(() => {
    const ids = Object.keys(formik.values.disks);

    return {
      ids,
    };
  }, [formik.values.disks]);

  const files = useMemo(() => {
    const uuids = Object.keys(resources.files);

    return {
      uuids,
    };
  }, [resources.files]);

  const nodes = useMemo(() => {
    const uuids = Object.keys(resources.nodes);

    const values = Object.values(resources.nodes);

    return {
      uuids,
      values,
    };
  }, [resources.nodes]);

  const oses = useMemo(() => {
    const keys = Object.keys(lsos);

    return {
      keys,
    };
  }, [lsos]);

  const storageGroups = useMemo(() => {
    const uuids = Object.keys(resources.storageGroups);

    return {
      uuids,
    };
  }, [resources.storageGroups]);

  const cpuCoresOptions = useMemo<readonly string[]>(() => {
    const max = nodes.values.reduce<number>(
      (previous, node) => Math.max(previous, node.cpu.cores.total),
      0,
    );

    return Array.from({ length: max - 1 }, (value, key) => String(key + 1));
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

      const jobs = Object.values(file.jobs);

      const status = jobs.length > 0 ? <>Syncing</> : <>Ready</>;

      return (
        <li {...optionProps} key={`${field}-op-${uuid}`}>
          <Box width="100%">
            <BodyText inheritColour noWrap>
              {file.name}
            </BodyText>
            <SmallText inheritColour noWrap>
              {status}
            </SmallText>
          </Box>
        </li>
      );
    },
    [resources.files],
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
    <Grid container spacing="1em">
      <Grid item width="100%">
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains.name}
              label="Server name"
              name={chains.name}
              onChange={handleChange}
              value={formik.values.name}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <Autocomplete
          id={chains.cpu.cores}
          label="CPU cores"
          noOptionsText="No node has the requested cores"
          onChange={(event, value) => {
            formik.setFieldValue(chains.cpu.cores, value, true);
          }}
          openOnFocus
          options={cpuCoresOptions}
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
                name: chains.memory.value,
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
            storageGroups={storageGroups}
            resources={resources}
          />
        </Grid>
      ))}
      <Grid item width="100%">
        <Autocomplete
          filterOptions={filterFileOptions}
          getOptionLabel={getFileOptionLabel}
          id={chains.install}
          label="Install ISO"
          noOptionsText="No matching ISO"
          onChange={(event, value) => {
            formik.setFieldValue(chains.install, value, true);
          }}
          openOnFocus
          options={files.uuids}
          renderOption={(optionProps, uuid) =>
            renderFileOption(chains.install, optionProps, uuid)
          }
          value={formik.values.install}
        />
      </Grid>
      <Grid item width="100%">
        <Autocomplete
          filterOptions={filterFileOptions}
          getOptionLabel={getFileOptionLabel}
          id={chains.driver}
          label="Driver ISO"
          noOptionsText="No matching ISO"
          onChange={(event, value) => {
            formik.setFieldValue(chains.driver, value, true);
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
          getOptionLabel={(uuid) => {
            const { [uuid]: node } = resources.nodes;

            return node.name;
          }}
          id={chains.node}
          label="Node"
          noOptionsText="No matching node"
          onChange={(event, value) => {
            formik.setFieldValue(chains.node, value, true);
          }}
          openOnFocus
          options={nodes.uuids}
          renderOption={(optionProps, uuid) => {
            const { [uuid]: node } = resources.nodes;

            return (
              <li {...optionProps} key={`node-op-${uuid}`}>
                <Grid container>
                  <Grid item xs>
                    <BodyText inheritColour noWrap>
                      {node.name}
                    </BodyText>
                    <SmallText inheritColour noWrap>
                      {node.description}
                    </SmallText>
                  </Grid>
                  <Grid item>
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
            formik.setFieldValue(chains.os, value, true);
          }}
          openOnFocus
          options={oses.keys}
          renderOption={(optionProps, osKey) => {
            const { [osKey]: os } = lsos;

            return (
              <li {...optionProps} key={`os-op-${osKey}`}>
                <Box width="100%">
                  <BodyText inheritColour noWrap>
                    {os}
                  </BodyText>
                  <SmallText inheritColour noWrap>
                    {osKey}
                  </SmallText>
                </Box>
              </li>
            );
          }}
        />
      </Grid>
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
    </Grid>
  );
};

export default ProvisionServerForm;
