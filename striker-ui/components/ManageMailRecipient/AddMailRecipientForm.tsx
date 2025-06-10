import { Grid, menuClasses as muiMenuClasses } from '@mui/material';
import { AxiosError } from 'axios';
import { useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import FlexBox from '../FlexBox';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import mailRecipientListSchema from './schema';
import ManageAlertOverride from './ManageAlertOverride';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import SelectWithLabel from '../SelectWithLabel';
import { BodyText, SmallText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

/**
 * TODO: add descriptions to each item:
 *
  =head4 1 / critical

  Alerts at this level will go to all recipients, except for those ignoring the source system entirely.

  This is reserved for alerts that could lead to imminent service interruption or unexpected loss of redundancy.

  Alerts at this level should trigger alarm systems for all administrators as well as management who may be impacted by service interruptions.

  =head4 2 / warning

  This is used for alerts that require attention from administrators. Examples include intentional loss of redundancy caused by load shedding, hardware in pre-failure, loss of input power, temperature anomalies, etc.

  Alerts at this level should trigger alarm systems for administrative staff.

  =head4 3 / notice

  This is used for alerts that are generally safe to ignore, but might provide early warnings of developing issues or insight into system behaviour. 

  Alerts at this level should not trigger alarm systems. Periodic review is sufficient.

  =head4 4 / info

  This is used for alerts that are almost always safe to ignore, but may be useful in testing and debugging. 
* 
*/
const LEVEL_OPTIONS: SelectItem<number>[] = [
  {
    displayValue: (
      <FlexBox spacing={0}>
        <BodyText inheritColour fontWeight="inherit">
          Critical
        </BodyText>
        <SmallText inheritColour whiteSpace="normal">
          Alerts that could lead to imminent service interruption or unexpected
          loss of redundancy.
        </SmallText>
      </FlexBox>
    ),
    value: 1,
  },
  {
    displayValue: (
      <FlexBox spacing={0}>
        <BodyText inheritColour fontWeight="inherit">
          Warning
        </BodyText>
        <SmallText inheritColour whiteSpace="normal">
          Alerts that require attention from administrators, such as redundancy
          loss due to load shedding, hardware in pre-failure, input power loss,
          temperature anomalies, etc.
        </SmallText>
      </FlexBox>
    ),
    value: 2,
  },
  {
    displayValue: (
      <FlexBox spacing={0}>
        <BodyText inheritColour fontWeight="inherit">
          Notice
        </BodyText>
        <SmallText inheritColour whiteSpace="normal">
          Alerts that are generally safe to ignore, but might provide early
          warnings of developing issues or insight into system behaviour.
        </SmallText>
      </FlexBox>
    ),
    value: 3,
  },
  {
    displayValue: (
      <FlexBox spacing={0}>
        <BodyText inheritColour fontWeight="inherit">
          Info
        </BodyText>
        <SmallText inheritColour whiteSpace="normal">
          Alerts that are almost always safe to ignore, but may be useful in
          testing and debugging.
        </SmallText>
      </FlexBox>
    ),
    value: 4,
  },
];

const MAP_TO_LEVEL_LABEL: Record<number, string> = {
  1: 'Critical',
  2: 'Warning',
  3: 'Notice',
  4: 'Info',
};

const getAlertOverrideRequestList = (
  current: MailRecipientFormikMailRecipient,
  initial?: MailRecipientFormikMailRecipient,
  urlPrefix = '/alert-override',
): AlertOverrideRequest[] => {
  const { uuid: mailRecipientUuid } = current;

  if (!mailRecipientUuid) return [];

  return Object.values(current.alertOverrides).reduce<AlertOverrideRequest[]>(
    (previous, { remove, level, target, uuids: existingOverrides }) => {
      /**
       * There's no update, just delete every record and create the new records.
       *
       * This is not optimal, but keep it until there's a better solution.
       */

      if (existingOverrides) {
        previous.push(
          ...Object.keys(existingOverrides).map<AlertOverrideRequest>(
            (overrideUuid) => ({
              method: 'delete',
              url: `${urlPrefix}/${overrideUuid}`,
            }),
          ),
        );
      }

      if (target && !remove) {
        const newHosts: string[] = target.subnodes ?? [target.uuid];

        previous.push(
          ...newHosts.map<AlertOverrideRequest>((hostUuid) => ({
            body: { hostUuid, level, mailRecipientUuid },
            method: 'post',
            url: urlPrefix,
          })),
        );
      }

      return previous;
    },
    [],
  );
};

const AddMailRecipientForm: React.FC<AddMailRecipientFormProps> = (props) => {
  const {
    alertOverrideTargetOptions,
    mailRecipientUuid,
    previousFormikValues,
    tools,
  } = props;

  const mrUuid = useMemo<string>(
    () => mailRecipientUuid ?? uuidv4(),
    [mailRecipientUuid],
  );

  const formikUtils = useFormikUtils<MailRecipientFormikValues>({
    initialValues: previousFormikValues ?? {
      [mrUuid]: {
        alertOverrides: {},
        email: '',
        language: 'en_CA',
        level: 2,
        name: '',
      },
    },
    onSubmit: (values, { setSubmitting }) => {
      const { [mrUuid]: mailRecipient } = values;

      let actionProceedText: string = 'Add';
      let errorMessage: React.ReactNode = <>Failed to add mail recipient.</>;
      let method: 'post' | 'put' = 'post';
      let successMessage: React.ReactNode = <>Mail recipient added.</>;
      let titleText: string = `Add mail recipient with the following?`;
      let url: string = '/mail-recipient';

      if (previousFormikValues) {
        actionProceedText = 'Update';
        errorMessage = <>Failed to update mail server.</>;
        method = 'put';
        successMessage = <>Mail recipient updated.</>;
        titleText = `Update ${mailRecipient.name} with the following?`;
        url += `/${mrUuid}`;
      }

      const { alertOverrides, uuid: ignore, ...mrBody } = mailRecipient;

      tools.confirm.prepare({
        actionProceedText,
        content: (
          <>
            <FormSummary entries={mrBody} />
            <FormSummary
              entries={{
                alertOverrides: Object.entries(alertOverrides).reduce<
                  Record<string, { level: number; name: string }>
                >((previous, [valueId, value]) => {
                  if (value.remove || !value.target) return previous;

                  previous[valueId] = {
                    level: value.level,
                    name: value.target.name,
                  };

                  return previous;
                }, {}),
              }}
            />
          </>
        ),
        onCancelAppend: () => setSubmitting(false),
        onProceedAppend: async () => {
          tools.confirm.loading(true);

          const handleError = (error: AxiosError) => {
            const emsg = handleAPIError(error);

            emsg.children = (
              <>
                {errorMessage} {emsg.children}
              </>
            );

            tools.confirm.finish('Error', emsg);

            setSubmitting(false);
          };

          // Handle the mail recipient first, wait until it's done to process
          // the related alert override records.

          api[method](url, mrBody)
            .then((response) => {
              const { data } = response;

              const shallow = { ...mailRecipient };

              if (data) {
                shallow.uuid = data.uuid;
              }

              const initial =
                previousFormikValues && previousFormikValues[mrUuid];

              const promises = getAlertOverrideRequestList(
                shallow,
                initial,
              ).map((request) =>
                api[request.method](request.url, request.body),
              );

              Promise.all(promises)
                .then(() => {
                  tools.confirm.finish('Success', { children: successMessage });

                  tools[method === 'post' ? 'add' : 'edit'].open(false);
                })
                .catch(handleError);
            })
            .catch(handleError);
        },
        titleText,
      });

      tools.confirm.open(true);
    },
    validationSchema: mailRecipientListSchema,
  });

  const { disabledSubmit, formik, formikErrors, handleChange } = formikUtils;

  const emailChain = useMemo<string>(() => `${mrUuid}.email`, [mrUuid]);
  const levelChain = useMemo<string>(() => `${mrUuid}.level`, [mrUuid]);
  const nameChain = useMemo<string>(() => `${mrUuid}.name`, [mrUuid]);

  return (
    <Grid
      columns={{ xs: 1, sm: 2 }}
      component="form"
      container
      onSubmit={(event) => {
        event.preventDefault();

        formik.submitForm();
      }}
      spacing="1em"
    >
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={nameChain}
              label="Recipient name"
              name={nameChain}
              onChange={handleChange}
              required
              value={formik.values[mrUuid].name}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={emailChain}
              label="Recipient email"
              name={emailChain}
              onChange={handleChange}
              required
              value={formik.values[mrUuid].email}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <SelectWithLabel
              id={levelChain}
              label="Alert level"
              name={levelChain}
              onChange={formik.handleChange}
              required
              selectItems={LEVEL_OPTIONS}
              selectProps={{
                MenuProps: {
                  sx: {
                    [`& .${muiMenuClasses.paper}`]: {
                      maxWidth: { md: '60%', lg: '40%' },
                    },
                  },
                },
                renderValue: (value) => MAP_TO_LEVEL_LABEL[value],
              }}
              value={formik.values[mrUuid].level}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <ManageAlertOverride
          alertOverrideTargetOptions={alertOverrideTargetOptions}
          formikUtils={formikUtils}
          mailRecipientUuid={mrUuid}
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
              children: previousFormikValues ? 'Update' : 'Add',
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default AddMailRecipientForm;
