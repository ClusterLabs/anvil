import Grid from '@mui/material/Grid';
import { useMemo } from 'react';

import handleAction from './handleAction';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { buildDeleteSchema } from './schemas';
import ServerFormGrid from './ServerFormGrid';
import ServerFormSubmit from './ServerFormSubmit';
import { BodyText, InlineMonoText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const ServerDeletion: React.FC<ServerDeletionProps> = (props) => {
  const { detail, tools } = props;

  const formikUtils = useFormikUtils<ServerDeletionFormikValues>({
    initialValues: {
      name: '',
    },
    onSubmit: (values, helpers) => {
      handleAction(
        tools,
        `/server/${detail.uuid}`,
        `Delete server ${detail.name}?`,
        {
          description: (
            <BodyText>
              Are you sure you want to delete the server {detail.name}? This
              action is not reversible!
            </BodyText>
          ),
          dangerous: true,
          method: 'delete',
          messages: {
            fail: <>Failed to register server deletion job.</>,
            proceed: 'Delete',
            success: <>Successfully registered server deletion job</>,
          },
          onCancel: () => {
            helpers.setSubmitting(false);
          },
          onFail: () => {
            helpers.setSubmitting(false);
          },
          onSuccess: () => {
            window.location.replace('/');
          },
        },
      );
    },
    validationSchema: buildDeleteSchema(detail),
  });

  const { disabledSubmit, formik, handleChange } = formikUtils;

  const chains = useMemo(
    () => ({
      name: 'name',
    }),
    [],
  );

  return (
    <ServerFormGrid<ServerDeletionFormikValues>
      formik={formik}
      justifyContent="center"
    >
      <Grid item width="100%">
        <BodyText>
          Deleting <InlineMonoText>{detail.name}</InlineMonoText> will remove
          all of its data, including its configurations and storage volume(s).
        </BodyText>
        <BodyText>
          Please type the server name to ensure the correct server gets deleted.
        </BodyText>
      </Grid>
      <Grid item>
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
        <ServerFormSubmit
          dangerous
          detail={detail}
          formDisabled={disabledSubmit}
          label="Delete"
        />
      </Grid>
    </ServerFormGrid>
  );
};

export default ServerDeletion;
