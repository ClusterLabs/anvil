import { Dispatch, FC, SetStateAction, useState } from 'react';
import { Box as MUIBox } from '@mui/material';

import ContainedButton, { ContainedButtonProps } from './ContainedButton';
import FlexBox from './FlexBox';
import NetworkInitForm from './NetworkInitForm';
import { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import pad from '../lib/pad';
import { Panel, PanelHeader } from './Panels';
import { HeaderText } from './Text';

const MAX_ORGANIZATION_PREFIX_LENGTH = 5;
const MIN_ORGANIZATION_PREFIX_LENGTH = 2;
const MAX_HOST_NUMBER_LENGTH = 2;

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

export type MapToValueIsEmptyFunction = {
  [TypeName in keyof MapToType]: (value: MapToType[TypeName]) => boolean;
};

export type InputOnChangeParameters = Parameters<
  Exclude<OutlinedInputProps['onChange'], undefined>
>;

const MAP_TO_VALUE_CONVERTER: MapToValueConverter = {
  number: (value) => parseInt(String(value), 10) || 0,
  string: (value) => String(value),
};

const MAP_TO_VALUE_IS_EMPTY_FUNCTION: MapToValueIsEmptyFunction = {
  number: (value: number) => value === 0,
  string: (value: string) => value.trim().length === 0,
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

const isEmpty = <TypeName extends keyof MapToType>(
  values: Array<MapToType[TypeName]>,
  { not, fn = 'every' }: { not?: boolean; fn?: 'every' | 'some' },
) =>
  values[fn]((value) => {
    const type = typeof value as TypeName;

    let result = MAP_TO_VALUE_IS_EMPTY_FUNCTION[type](value);

    if (not) {
      result = !result;
    }

    return result;
  });

const createFunction = (
  {
    conditionFn = () => true,
    str = '',
    condition = conditionFn() && str.length === 0,
  }: {
    condition?: boolean;
    conditionFn?: (...args: unknown[]) => boolean;
    str?: string;
  },
  fn: () => unknown,
  ...fnArgs: Parameters<typeof fn>
) => (condition ? fn.bind(null, ...fnArgs) : undefined);

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
) =>
  isEmpty([organizationPrefix, hostNumber, domainName], { not: true })
    ? `${organizationPrefix}-striker${pad(hostNumber)}.${domainName}`
    : '';

const SuggestButton: FC<ContainedButtonProps> = ({ onClick, ...restProps }) =>
  onClick ? (
    <ContainedButton {...{ onClick, tabIndex: -1, ...restProps }}>
      Suggest
    </ContainedButton>
  ) : (
    <></>
  );

const StrikerInitGeneralForm: FC = () => {
  const [organizationNameInput, setOrganizationNameInput] =
    useState<string>('');
  const [organizationPrefixInput, setOrganizationPrefixInput] =
    useState<string>('');
  const [
    isOrganizationPrefixInputUserChanged,
    setIsOrganizationPrefixInputUserChanged,
  ] = useState<boolean>(false);
  const [domainNameInput, setDomainNameInput] = useState<string>('');
  const [hostNumberInput, setHostNumberInput] = useState<number>(0);
  const [hostNameInput, setHostNameInput] = useState<string>('');
  const [isHostNameInputUserChanged, setIsHostNameInputUserChanged] =
    useState<boolean>(false);

  const handleOrganizationNameInputOnChange = createInputOnChangeHandler({
    set: setOrganizationNameInput,
  });
  const handleOrganizationPrefixInputOnChange = createInputOnChangeHandler({
    postSet: () => {
      setIsOrganizationPrefixInputUserChanged(true);
    },
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
    postSet: () => {
      setIsHostNameInputUserChanged(true);
    },
    set: setHostNameInput,
  });
  const populateOrganizationPrefixInput = ({
    organizationName = organizationNameInput,
  } = {}) => {
    const organizationPrefix = buildOrganizationPrefix(organizationName);

    setOrganizationPrefixInput(organizationPrefix);

    return organizationPrefix;
  };
  const populateHostNameInput = ({
    organizationPrefix = organizationPrefixInput,
    hostNumber = hostNumberInput,
    domainName = domainNameInput,
  } = {}) => {
    const hostName = buildHostName(organizationPrefix, hostNumber, domainName);

    setHostNameInput(hostName);

    return hostName;
  };
  const populateOrganizationPrefixInputOnBlur = createFunction(
    { condition: !isOrganizationPrefixInputUserChanged },
    populateOrganizationPrefixInput,
  );
  const populateHostNameInputOnBlur = createFunction(
    { condition: !isHostNameInputUserChanged },
    populateHostNameInput,
  );
  const handleOrganizationPrefixSuggest = createFunction(
    {
      conditionFn: () =>
        isOrganizationPrefixInputUserChanged &&
        isEmpty([organizationNameInput], { not: true }),
    },
    () => {
      const organizationPrefix = populateOrganizationPrefixInput();

      if (!isHostNameInputUserChanged) {
        populateHostNameInput({ organizationPrefix });
      }
    },
  );
  const handlerHostNameSuggest = createFunction(
    {
      conditionFn: () =>
        isHostNameInputUserChanged &&
        isEmpty([organizationPrefixInput, hostNumberInput, domainNameInput], {
          not: true,
        }),
    },
    populateHostNameInput,
  );

  return (
    <MUIBox
      sx={{
        display: 'flex',
        flexDirection: { xs: 'column', sm: 'row' },

        '& > *': {
          flexBasis: '50%',
        },

        '& > :not(:first-child)': {
          marginLeft: { xs: 0, sm: '1em' },
          marginTop: { xs: '1em', sm: 0 },
        },
      }}
    >
      <FlexBox>
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: 'Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you.',
          }}
          id="striker-init-general-organization-name"
          inputProps={{
            onBlur: populateOrganizationPrefixInputOnBlur,
          }}
          label="Organization name"
          onChange={handleOrganizationNameInputOnChange}
          value={organizationNameInput}
        />
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Alphanumberic short-form of the organization name. It's used as the prefix for host names.",
          }}
          id="striker-init-general-organization-prefix"
          inputProps={{
            endAdornment: (
              <SuggestButton onClick={handleOrganizationPrefixSuggest} />
            ),
            inputProps: {
              maxLength: MAX_ORGANIZATION_PREFIX_LENGTH,
              style: { width: '2.5em' },
            },
            onBlur: populateHostNameInputOnBlur,
            sx: {
              minWidth: 'min-content',
              width: 'fit-content',
            },
          }}
          label="Prefix"
          onChange={handleOrganizationPrefixInputOnChange}
          value={organizationPrefixInput}
        />
      </FlexBox>
      <FlexBox>
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Domain name for this striker. It's also the default domain used when creating new install manifests.",
          }}
          id="striker-init-general-domain-name"
          inputProps={{
            onBlur: populateHostNameInputOnBlur,
            sx: {
              minWidth: { sm: '16em' },
              width: { xs: '100%', sm: '50%' },
            },
          }}
          label="Domain name"
          onChange={handleDomainNameInputOnChange}
          value={domainNameInput}
        />
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Number or count of this striker; this should be '1' for the first striker, '2' for the second striker, and such.",
          }}
          id="striker-init-general-host-number"
          inputProps={{
            inputProps: { maxLength: MAX_HOST_NUMBER_LENGTH },
            onBlur: populateHostNameInputOnBlur,
            sx: {
              width: '5em',
            },
          }}
          label="Host #"
          onChange={handleHostNumberInputOnChange}
          value={hostNumberInput}
        />
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Host name for this striker. It's usually a good idea to use the auto-generated value.",
          }}
          id="striker-init-general-host-name"
          inputProps={{
            endAdornment: <SuggestButton onClick={handlerHostNameSuggest} />,
            inputProps: {
              style: {
                minWidth: '4em',
              },
            },
            sx: {
              minWidth: 'min-content',
            },
          }}
          label="Host name"
          onChange={handleHostNameInputOnChange}
          value={hostNameInput}
        />
      </FlexBox>
    </MUIBox>
  );
};

const StrikerInitForm: FC = () => (
  <Panel>
    <PanelHeader>
      <HeaderText text="Initialize striker" />
    </PanelHeader>
    <FlexBox>
      <StrikerInitGeneralForm />
      <NetworkInitForm />
    </FlexBox>
  </Panel>
);

export default StrikerInitForm;
