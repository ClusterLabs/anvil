import { FormGroup } from '@mui/material';
import { cloneDeep, debounce } from 'lodash';
import { FC, useCallback, useMemo } from 'react';

import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

import FlexBox from '../FlexBox';
import List from '../List';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { ExpandablePanel } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';

const FileInputGroup: FC<FileInputGroupProps> = (props) => {
  const {
    anvils,
    drHosts,
    fileUuid: fuuid,
    formik,
    showSyncInputGroup,
    showTypeInput,
  } = props;

  const { handleBlur, handleChange } = formik;

  const debounceChangeEventHandler = useMemo(
    () => debounce(handleChange, 500),
    [handleChange],
  );

  const { nameChain, locationsChain, typeChain } = useMemo(
    () => ({
      nameChain: `${fuuid}.name`,
      locationsChain: `${fuuid}.locations`,
      typeChain: `${fuuid}.type`,
    }),
    [fuuid],
  );

  const handleCheckAllLocations = useCallback(
    (type: keyof FileFormikLocations, checked: boolean) => {
      formik.setValues((previous: FileFormikValues) => {
        const current = cloneDeep(previous);
        const locations = current[fuuid].locations?.[type];

        if (!locations) return previous;

        Object.keys(locations).forEach((key) => {
          locations[key].active = checked;
        });

        return current;
      });
    },
    [formik, fuuid],
  );

  const getAllLocationsCheckboxProps = useCallback(
    (type: keyof FileFormikLocations): CheckboxProps => {
      const locations = formik.values[fuuid].locations?.[type] as {
        [uuid: string]: { active: boolean };
      };

      if (!locations) return {};

      return {
        checked: Object.values(locations).every(({ active }) => active),
        onChange: (event, checked) => {
          handleCheckAllLocations(type, checked);
        },
      };
    },
    [formik.values, fuuid, handleCheckAllLocations],
  );

  const getLocationCheckboxProps = useCallback(
    (type: keyof FileFormikLocations, uuid: string): CheckboxProps => {
      const gridChain = `${locationsChain}.${type}.${uuid}`;
      const activeChain = `${gridChain}.active`;

      return {
        id: activeChain,
        name: activeChain,
        checked: formik.values[fuuid].locations?.[type]?.[uuid]?.active,
        onBlur: handleBlur,
        onChange: handleChange,
      };
    },
    [formik.values, fuuid, handleBlur, handleChange, locationsChain],
  );

  const enableCheckAllLocations = useCallback(
    (type: keyof FileFormikLocations) => {
      const locations = formik.values[fuuid].locations?.[type];

      return locations && Object.keys(locations).length > 1;
    },
    [formik.values, fuuid],
  );

  const nameInput = useMemo(
    () => (
      <UncontrolledInput
        input={
          <OutlinedInputWithLabel
            id={nameChain}
            label="File name"
            name={nameChain}
            onBlur={handleBlur}
            onChange={debounceChangeEventHandler}
            value={formik.values[fuuid].name}
          />
        }
      />
    ),
    [debounceChangeEventHandler, formik.values, fuuid, handleBlur, nameChain],
  );

  const syncNodeInputGroup = useMemo(
    () =>
      showSyncInputGroup && (
        <ExpandablePanel
          header="Sync with node(s)"
          panelProps={{ mb: 0, mt: 0, width: '100%' }}
        >
          <List
            allowCheckAll={enableCheckAllLocations('anvils')}
            allowCheckItem
            edit
            header
            listItems={anvils}
            getListCheckboxProps={() => getAllLocationsCheckboxProps('anvils')}
            getListItemCheckboxProps={(uuid) =>
              getLocationCheckboxProps('anvils', uuid)
            }
            renderListItem={(anvilUuid, { description, name }) => (
              <BodyText>
                {name}: {description}
              </BodyText>
            )}
          />
        </ExpandablePanel>
      ),
    [
      anvils,
      enableCheckAllLocations,
      getAllLocationsCheckboxProps,
      getLocationCheckboxProps,
      showSyncInputGroup,
    ],
  );

  const syncDrHostInputGroup = useMemo(
    () =>
      showSyncInputGroup && (
        <ExpandablePanel
          header="Sync with DR host(s)"
          panelProps={{ mb: 0, mt: 0, width: '100%' }}
        >
          <List
            allowCheckAll={enableCheckAllLocations('drHosts')}
            allowCheckItem
            edit
            header
            listItems={drHosts}
            getListCheckboxProps={() => getAllLocationsCheckboxProps('drHosts')}
            getListItemCheckboxProps={(uuid) =>
              getLocationCheckboxProps('drHosts', uuid)
            }
            renderListItem={(anvilUuid, { hostName }) => (
              <BodyText>{hostName}</BodyText>
            )}
          />
        </ExpandablePanel>
      ),
    [
      drHosts,
      enableCheckAllLocations,
      getAllLocationsCheckboxProps,
      getLocationCheckboxProps,
      showSyncInputGroup,
    ],
  );

  const typeInput = useMemo(
    () =>
      showTypeInput && (
        <SelectWithLabel
          id={typeChain}
          label="File type"
          name={typeChain}
          onBlur={handleBlur}
          onChange={handleChange}
          selectItems={UPLOAD_FILE_TYPES_ARRAY.map(
            ([value, [, displayValue]]) => ({
              displayValue,
              value,
            }),
          )}
          value={formik.values[fuuid].type}
        />
      ),
    [formik.values, fuuid, handleBlur, handleChange, showTypeInput, typeChain],
  );

  return (
    <FormGroup sx={{ '& > :not(:first-child)': { marginTop: '1em' } }}>
      <FlexBox sm="row" xs="column">
        {nameInput}
        {typeInput}
      </FlexBox>
      {syncNodeInputGroup}
      {syncDrHostInputGroup}
    </FormGroup>
  );
};

export default FileInputGroup;
