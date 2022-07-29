import { Grid as MUIGrid } from '@mui/material';
import {
  forwardRef,
  ReactNode,
  useCallback,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';

import FlexBox from './FlexBox';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import isEmpty from '../lib/isEmpty';
import MessageBox from './MessageBox';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import pad from '../lib/pad';
import SuggestButton from './SuggestButton';

type GeneralInitFormForwardRefContent = {
  get?: () => {
    adminPassword?: string;
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
    const [helpMessage, setHelpText] = useState<ReactNode | undefined>();
    const [
      isShowOrganizationPrefixSuggest,
      setIsShowOrganizationPrefixSuggest,
    ] = useState<boolean>(false);
    const [isShowHostNameSuggest, setIsShowHostNameSuggest] =
      useState<boolean>(false);

    const adminPasswordInputRef = useRef<InputForwardedRefContent<'string'>>(
      {},
    );
    const confirmAdminPasswordInputRef = useRef<
      InputForwardedRefContent<'string'>
    >({});
    const organizationNameInputRef = useRef<InputForwardedRefContent<'string'>>(
      {},
    );
    const organizationPrefixInputRef = useRef<
      InputForwardedRefContent<'string'>
    >({});
    const domainNameInputRef = useRef<InputForwardedRefContent<'string'>>({});
    const hostNumberInputRef = useRef<InputForwardedRefContent<'number'>>({});
    const hostNameInputRef = useRef<InputForwardedRefContent<'string'>>({});

    const populateOrganizationPrefixInput = useCallback(
      ({
        organizationName = organizationNameInputRef.current.getValue?.call(
          null,
        ),
      } = {}) => {
        const organizationPrefix = buildOrganizationPrefix(organizationName);

        organizationPrefixInputRef.current.setValue?.call(
          null,
          organizationPrefix,
        );

        return organizationPrefix;
      },
      [],
    );
    const populateHostNameInput = useCallback(
      ({
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
      },
      [],
    );
    const isOrganizationPrefixPrereqFilled = useCallback(
      () =>
        isEmpty([organizationNameInputRef.current.getValue?.call(null)], {
          not: true,
        }),
      [],
    );
    const isHostNamePrereqFilled = useCallback(
      () =>
        isEmpty(
          [
            organizationPrefixInputRef.current.getValue?.call(null),
            hostNumberInputRef.current.getValue?.call(null),
            domainNameInputRef.current.getValue?.call(null),
          ],
          {
            not: true,
          },
        ),
      [],
    );
    const populateOrganizationPrefixInputOnBlur: OutlinedInputWithLabelOnBlur =
      useCallback(() => {
        if (organizationPrefixInputRef.current.getIsChangedByUser?.call(null)) {
          setIsShowOrganizationPrefixSuggest(
            isOrganizationPrefixPrereqFilled(),
          );
        } else {
          populateOrganizationPrefixInput();
        }
      }, [isOrganizationPrefixPrereqFilled, populateOrganizationPrefixInput]);
    const populateHostNameInputOnBlur: OutlinedInputWithLabelOnBlur =
      useCallback(() => {
        if (hostNameInputRef.current.getIsChangedByUser?.call(null)) {
          setIsShowHostNameSuggest(isHostNamePrereqFilled());
        } else {
          populateHostNameInput();
        }
      }, [isHostNamePrereqFilled, populateHostNameInput]);
    const handleOrganizationPrefixSuggest = useCallback(() => {
      const organizationPrefix = populateOrganizationPrefixInput();

      if (!hostNameInputRef.current.getIsChangedByUser?.call(null)) {
        populateHostNameInput({ organizationPrefix });
      }
    }, [populateHostNameInput, populateOrganizationPrefixInput]);
    const handlerHostNameSuggest = useCallback(() => {
      populateHostNameInput();
    }, [populateHostNameInput]);
    const buildHelpMessage = useCallback(
      (text: string) => (previous?: string) =>
        previous === text ? undefined : text,
      [],
    );

    useImperativeHandle(ref, () => ({
      get: () => ({
        adminPassword: adminPasswordInputRef.current.getValue?.call(null),
        organizationName: organizationNameInputRef.current.getValue?.call(null),
        organizationPrefix:
          organizationPrefixInputRef.current.getValue?.call(null),
        domainName: domainNameInputRef.current.getValue?.call(null),
        hostNumber: hostNumberInputRef.current.getValue?.call(null),
        hostName: hostNameInputRef.current.getValue?.call(null),
      }),
    }));

    return (
      <FlexBox>
        <MUIGrid columns={{ xs: 1, sm: 2, md: 3 }} container spacing="1em">
          <MUIGrid item xs={1}>
            <FlexBox>
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id="striker-init-general-organization-name"
                    inputProps={{
                      onBlur: populateOrganizationPrefixInputOnBlur,
                    }}
                    label="Organization name"
                    onHelp={() => {
                      setHelpText(
                        buildHelpMessage(
                          'Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you.',
                        ),
                      );
                    }}
                  />
                }
                ref={organizationNameInputRef}
              />
              <FlexBox
                row
                sx={{
                  '& > *': {
                    flexBasis: '50%',
                  },
                }}
              >
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
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
                        },
                        onBlur: populateHostNameInputOnBlur,
                      }}
                      label="Prefix"
                      onChange={() => {
                        setIsShowOrganizationPrefixSuggest(
                          isOrganizationPrefixPrereqFilled(),
                        );
                      }}
                      onHelp={() => {
                        setHelpText(
                          buildHelpMessage(
                            "Alphanumberic short-form of the organization name. It's used as the prefix for host names.",
                          ),
                        );
                      }}
                    />
                  }
                  ref={organizationPrefixInputRef}
                />
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id="striker-init-general-host-number"
                      inputProps={{
                        inputProps: {
                          maxLength: MAX_HOST_NUMBER_LENGTH,
                        },
                        onBlur: populateHostNameInputOnBlur,
                      }}
                      label="Host #"
                      onHelp={() => {
                        setHelpText(
                          buildHelpMessage(
                            "Number or count of this striker; this should be '1' for the first striker, '2' for the second striker, and such.",
                          ),
                        );
                      }}
                    />
                  }
                  ref={hostNumberInputRef}
                  valueType="number"
                />
              </FlexBox>
            </FlexBox>
          </MUIGrid>
          <MUIGrid item xs={1}>
            <FlexBox>
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id="striker-init-general-domain-name"
                    inputProps={{
                      onBlur: populateHostNameInputOnBlur,
                    }}
                    label="Domain name"
                    onHelp={() => {
                      setHelpText(
                        buildHelpMessage(
                          "Domain name for this striker. It's also the default domain used when creating new install manifests.",
                        ),
                      );
                    }}
                  />
                }
                ref={domainNameInputRef}
              />

              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id="striker-init-general-host-name"
                    inputProps={{
                      endAdornment: (
                        <SuggestButton
                          show={isShowHostNameSuggest}
                          onClick={handlerHostNameSuggest}
                        />
                      ),
                    }}
                    label="Host name"
                    onChange={() => {
                      setIsShowHostNameSuggest(isHostNamePrereqFilled());
                    }}
                    onHelp={() => {
                      setHelpText(
                        buildHelpMessage(
                          "Host name for this striker. It's usually a good idea to use the auto-generated value.",
                        ),
                      );
                    }}
                  />
                }
                ref={hostNameInputRef}
              />
            </FlexBox>
          </MUIGrid>
          <MUIGrid item xs={1} sm={2} md={1}>
            <MUIGrid
              columns={{ xs: 1, sm: 2, md: 1 }}
              container
              spacing="1em"
              sx={{
                '& > * > *': {
                  width: '100%',
                },
              }}
            >
              <MUIGrid item xs={1}>
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id="striker-init-general-admin-password"
                      inputProps={{
                        inputProps: {
                          type: 'password',
                        },
                      }}
                      label="Admin password"
                      onHelp={() => {
                        setHelpText(
                          buildHelpMessage(
                            "Password use to login to this Striker and connect to its database. Don't reuse an existing password here because it'll be stored as plaintext.",
                          ),
                        );
                      }}
                    />
                  }
                  ref={adminPasswordInputRef}
                />
              </MUIGrid>
              <MUIGrid item xs={1}>
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id="striker-init-general-confirm-admin-password"
                      inputProps={{
                        inputProps: {
                          type: 'password',
                        },
                      }}
                      label="Confirm password"
                    />
                  }
                  ref={confirmAdminPasswordInputRef}
                />
              </MUIGrid>
            </MUIGrid>
          </MUIGrid>
        </MUIGrid>
        {helpMessage && (
          <MessageBox
            onClose={() => {
              setHelpText(undefined);
            }}
          >
            {helpMessage}
          </MessageBox>
        )}
      </FlexBox>
    );
  },
);

GeneralInitForm.displayName = 'GeneralInitForm';

export type { GeneralInitFormForwardRefContent };

export default GeneralInitForm;
