import { Box as MUIBox } from '@mui/material';
import { forwardRef, useImperativeHandle, useRef, useState } from 'react';

import FlexBox from './FlexBox';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import isEmpty from '../lib/isEmpty';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import pad from '../lib/pad';
import SuggestButton from './SuggestButton';

type GeneralInitFormForwardRefContent = {
  get?: () => {
    organizationName?: string;
    organizationPrefix?: string;
    domainName?: string;
    hostNumber?: number;
    hostName?: string;
  };
};

type OutlinedInputWithLabelOnBlur = Exclude<
  OutlinedInputWithLabelProps['inputProps'],
  undefined
>['onBlur'];

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

const buildOrganizationPrefix = (organizationName = '') => {
  const words: string[] = organizationName
    .split(/\s/)
    .filter((word) => !/and|of/.test(word))
    .slice(0, MAX_ORGANIZATION_PREFIX_LENGTH);

  const builderKey: number = words.length > 1 ? 2 : words.length;

  return MAP_TO_ORGANIZATION_PREFIX_BUILDER[builderKey](words);
};

const buildHostName = ({
  organizationPrefix,
  hostNumber,
  domainName,
}: {
  organizationPrefix?: string;
  hostNumber?: number;
  domainName?: string;
}) =>
  isEmpty([organizationPrefix, hostNumber, domainName], { not: true })
    ? `${organizationPrefix}-striker${pad(hostNumber)}.${domainName}`
    : '';

const GeneralInitForm = forwardRef<GeneralInitFormForwardRefContent>(
  (generalInitFormProps, ref) => {
    const [
      isShowOrganizationPrefixSuggest,
      setIsShowOrganizationPrefixSuggest,
    ] = useState<boolean>(false);
    const [isShowHostNameSuggest, setIsShowHostNameSuggest] =
      useState<boolean>(false);

    const organizationNameInputRef = useRef<InputForwardedRefContent<'string'>>(
      {},
    );
    const organizationPrefixInputRef = useRef<
      InputForwardedRefContent<'string'>
    >({});
    const domainNameInputRef = useRef<InputForwardedRefContent<'string'>>({});
    const hostNumberInputRef = useRef<InputForwardedRefContent<'number'>>({});
    const hostNameInputRef = useRef<InputForwardedRefContent<'string'>>({});

    const populateOrganizationPrefixInput = ({
      organizationName = organizationNameInputRef.current.getValue?.call(null),
    } = {}) => {
      const organizationPrefix = buildOrganizationPrefix(organizationName);

      organizationPrefixInputRef.current.setValue?.call(
        null,
        organizationPrefix,
      );

      return organizationPrefix;
    };
    const populateHostNameInput = ({
      organizationPrefix = organizationPrefixInputRef.current.getValue?.call(
        null,
      ),
      hostNumber = hostNumberInputRef.current.getValue?.call(null),
      domainName = domainNameInputRef.current.getValue?.call(null),
    } = {}) => {
      const hostName = buildHostName({
        organizationPrefix,
        hostNumber,
        domainName,
      });

      hostNameInputRef.current.setValue?.call(null, hostName);

      return hostName;
    };
    const isOrganizationPrefixPrereqFilled = () =>
      isEmpty([organizationNameInputRef.current.getValue?.call(null)], {
        not: true,
      });
    const isHostNamePrereqFilled = () =>
      isEmpty(
        [
          organizationPrefixInputRef.current.getValue?.call(null),
          hostNumberInputRef.current.getValue?.call(null),
          domainNameInputRef.current.getValue?.call(null),
        ],
        {
          not: true,
        },
      );
    const populateOrganizationPrefixInputOnBlur: OutlinedInputWithLabelOnBlur =
      () => {
        if (organizationPrefixInputRef.current.getIsChangedByUser?.call(null)) {
          setIsShowOrganizationPrefixSuggest(
            isOrganizationPrefixPrereqFilled(),
          );
        } else {
          populateOrganizationPrefixInput();
        }
      };
    const populateHostNameInputOnBlur: OutlinedInputWithLabelOnBlur = () => {
      if (hostNameInputRef.current.getIsChangedByUser?.call(null)) {
        setIsShowHostNameSuggest(isHostNamePrereqFilled());
      } else {
        populateHostNameInput();
      }
    };
    const handleOrganizationPrefixSuggest = () => {
      const organizationPrefix = populateOrganizationPrefixInput();

      if (!hostNameInputRef.current.getIsChangedByUser?.call(null)) {
        populateHostNameInput({ organizationPrefix });
      }
    };
    const handlerHostNameSuggest = () => {
      populateHostNameInput();
    };

    useImperativeHandle(ref, () => ({
      get: () => ({
        organizationName: organizationNameInputRef.current.getValue?.call(null),
        organizationPrefix:
          organizationPrefixInputRef.current.getValue?.call(null),
        domainName: domainNameInputRef.current.getValue?.call(null),
        hostNumber: hostNumberInputRef.current.getValue?.call(null),
        hostName: hostNameInputRef.current.getValue?.call(null),
      }),
    }));

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
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                helpMessageBoxProps={{
                  text: 'Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you.',
                }}
                id="striker-init-general-organization-name"
                inputProps={{
                  onBlur: populateOrganizationPrefixInputOnBlur,
                }}
                label="Organization name"
              />
            }
            ref={organizationNameInputRef}
          />
          <FlexBox row>
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  helpMessageBoxProps={{
                    text: "Alphanumberic short-form of the organization name. It's used as the prefix for host names.",
                  }}
                  id="striker-init-general-organization-prefix"
                  inputProps={{
                    endAdornment: (
                      <SuggestButton
                        show={isShowOrganizationPrefixSuggest}
                        onClick={handleOrganizationPrefixSuggest}
                      />
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
                  onChange={() => {
                    setIsShowOrganizationPrefixSuggest(
                      isOrganizationPrefixPrereqFilled(),
                    );
                  }}
                />
              }
              ref={organizationPrefixInputRef}
            />
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  helpMessageBoxProps={{
                    text: "Number or count of this striker; this should be '1' for the first striker, '2' for the second striker, and such.",
                  }}
                  id="striker-init-general-host-number"
                  inputProps={{
                    inputProps: { maxLength: MAX_HOST_NUMBER_LENGTH },
                    onBlur: populateHostNameInputOnBlur,
                    sx: {
                      width: '6em',
                    },
                  }}
                  label="Host #"
                />
              }
              ref={hostNumberInputRef}
              valueType="number"
            />
          </FlexBox>
        </FlexBox>
        <FlexBox>
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                helpMessageBoxProps={{
                  text: "Domain name for this striker. It's also the default domain used when creating new install manifests.",
                }}
                id="striker-init-general-domain-name"
                inputProps={{
                  onBlur: populateHostNameInputOnBlur,
                  sx: {
                    minWidth: { sm: '16em' },
                  },
                }}
                label="Domain name"
              />
            }
            ref={domainNameInputRef}
          />

          <InputWithRef
            input={
              <OutlinedInputWithLabel
                helpMessageBoxProps={{
                  text: "Host name for this striker. It's usually a good idea to use the auto-generated value.",
                }}
                id="striker-init-general-host-name"
                inputProps={{
                  endAdornment: (
                    <SuggestButton
                      show={isShowHostNameSuggest}
                      onClick={handlerHostNameSuggest}
                    />
                  ),
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
                onChange={() => {
                  setIsShowHostNameSuggest(isHostNamePrereqFilled());
                }}
              />
            }
            ref={hostNameInputRef}
          />
        </FlexBox>
      </MUIBox>
    );
  },
);

GeneralInitForm.displayName = 'GeneralInitForm';

export type { GeneralInitFormForwardRefContent };

export default GeneralInitForm;
