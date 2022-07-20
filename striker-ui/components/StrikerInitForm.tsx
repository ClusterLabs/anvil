import { Dispatch, FC, SetStateAction, useState } from 'react';
import { Box as MUIBox } from '@mui/material';

import NetworkInitForm from './NetworkInitForm';
import { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import { Panel, PanelHeader } from './Panels';
import { HeaderText } from './Text';
import pad from '../lib/pad';

const MAX_ORGANIZATION_PREFIX_LENGTH = 5;
const MIN_ORGANIZATION_PREFIX_LENGTH = 2;

const MAP_TO_ORGANIZATION_PREFIX_BUILDER: Record<
  number,
  (words: string[]) => string
> = {
  0: () => '',
  1: ([word]) =>
    word.substring(0, MIN_ORGANIZATION_PREFIX_LENGTH).toLocaleLowerCase(),
  2: (words) =>
    words.map((word) => word.substring(0, 1).toLocaleLowerCase()).join(''),
};

export type MapToType = {
  number: number;
  string: string;
};

export type MapToStateSetter = {
  [TypeName in keyof MapToType]: Dispatch<SetStateAction<MapToType[TypeName]>>;
};

export type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};

export type InputOnChangeParameters = Parameters<
  Exclude<OutlinedInputProps['onChange'], undefined>
>;

const MAP_TO_VALUE_CONVERTER: MapToValueConverter = {
  number: (value) => parseInt(String(value), 10) || 0,
  string: (value) => String(value),
};

const createInputOnChangeHandler =
  <TypeName extends keyof MapToType>({
    postSet,
    preSet,
    set,
    setType = 'string',
  }: {
    postSet?: (...args: InputOnChangeParameters) => void;
    preSet?: (...args: InputOnChangeParameters) => void;
    set?: MapToStateSetter[TypeName];
    setType?: TypeName | 'string';
  }): OutlinedInputProps['onChange'] =>
  (event) => {
    const {
      target: { value },
    } = event;
    const postConvertValue = MAP_TO_VALUE_CONVERTER[setType](
      value,
    ) as MapToType[TypeName];

    preSet?.call(null, event);
    set?.call(null, postConvertValue);
    postSet?.call(null, event);
  };

const buildOrganizationPrefix = (organizationName: string) => {
  const words: string[] = organizationName
    .split(/\s/)
    .filter((word) => !/and|of/.test(word))
    .slice(0, MAX_ORGANIZATION_PREFIX_LENGTH);

  const builderKey: number = words.length > 1 ? 2 : words.length;

  return MAP_TO_ORGANIZATION_PREFIX_BUILDER[builderKey](words);
};

const buildHostName = (
  organizationPrefix: string,
  hostNumber: number,
  domainName: string,
  existingHostName = '',
) =>
  organizationPrefix.length > 0 && hostNumber > 0 && domainName.length > 0
    ? `${organizationPrefix}-striker${pad(hostNumber)}.${domainName}`
    : existingHostName;

const StrikerInitGeneralForm: FC = () => {
  const [organizationNameInput, setOrganizationNameInput] =
    useState<string>('');
  const [organizationPrefixInput, setOrganizationPrefixInput] =
    useState<string>('');
  const [domainNameInput, setDomainNameInput] = useState<string>('');
  const [hostNumberInput, setHostNumberInput] = useState<number>(0);
  const [hostNameInput, setHostNameInput] = useState<string>('');

  const handleOrganizationNameInputOnChange = createInputOnChangeHandler({
    set: setOrganizationNameInput,
  });
  const handleOrganizationPrefixInputOnChange = createInputOnChangeHandler({
    set: setOrganizationPrefixInput,
  });
  const handleDomainNameInputOnChange = createInputOnChangeHandler({
    set: setDomainNameInput,
  });
  const handleHostNumberInputOnChange = createInputOnChangeHandler({
    set: setHostNumberInput,
    setType: 'number',
  });
  const handleHostNameInputOnChange = createInputOnChangeHandler({
    set: setHostNameInput,
  });

  return (
    <MUIBox
      sx={{
        display: 'flex',
        flexDirection: 'column',

        '& > :not(:first-child)': {
          marginTop: '1em',
        },
      }}
    >
      <OutlinedInputWithLabel
        inputProps={{
          onBlur: ({ target: { value } }) => {
            const newOrganizationName = String(value);

            setOrganizationPrefixInput(
              buildOrganizationPrefix(newOrganizationName),
            );
          },
        }}
        label="Organization name"
        onChange={handleOrganizationNameInputOnChange}
        value={organizationNameInput}
      />
      <OutlinedInputWithLabel
        inputProps={{
          onBlur: ({ target: { value } }) => {
            const newOrganizationPrefix = String(value);

            setHostNameInput(
              buildHostName(
                newOrganizationPrefix,
                hostNumberInput,
                domainNameInput,
                hostNameInput,
              ),
            );
          },
        }}
        label="Organization prefix"
        onChange={handleOrganizationPrefixInputOnChange}
        value={organizationPrefixInput}
      />
      <OutlinedInputWithLabel
        label="Domain name"
        inputProps={{
          onBlur: ({ target: { value } }) => {
            const newDomainName = String(value);

            setHostNameInput(
              buildHostName(
                organizationPrefixInput,
                hostNumberInput,
                newDomainName,
                hostNameInput,
              ),
            );
          },
        }}
        onChange={handleDomainNameInputOnChange}
        value={domainNameInput}
      />
      <OutlinedInputWithLabel
        inputProps={{
          onBlur: ({ target: { value } }) => {
            const newHostNumber = parseInt(value, 10);

            setHostNameInput(
              buildHostName(
                organizationPrefixInput,
                newHostNumber,
                domainNameInput,
                hostNameInput,
              ),
            );
          },
        }}
        label="Host number"
        onChange={handleHostNumberInputOnChange}
        value={hostNumberInput}
      />
      <OutlinedInputWithLabel
        label="Host name"
        onChange={handleHostNameInputOnChange}
        value={hostNameInput}
      />
    </MUIBox>
  );
};

const StrikerInitForm: FC = () => (
  <Panel>
    <PanelHeader>
      <HeaderText text="Initialize striker" />
    </PanelHeader>
    <MUIBox
      sx={{
        display: 'flex',
        flexDirection: 'column',

        '& > :not(:first-child)': { marginTop: '1em' },
      }}
    >
      <StrikerInitGeneralForm />
      <NetworkInitForm />
    </MUIBox>
  </Panel>
);

export default StrikerInitForm;
