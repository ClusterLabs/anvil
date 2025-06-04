import { Grid } from '@mui/material';

import { REP_LABEL_PASSW } from '../../lib/consts/REG_EXP_PATTERNS';

import CrudList from '../CrudList';
import FenceForm from './FenceForm';
import { BodyText, HeaderText, InlineMonoText, SensitiveText } from '../Text';
import useFetch from '../../hooks/useFetch';

const ManageFenceList: React.FC = () => {
  const { data: fenceTemplate, loading: loadingFenceTemplate } =
    useFetch<APIFenceTemplate>(`/fence/template`);

  return (
    <CrudList<APIFenceOverview, APIFenceOverview>
      addHeader="Add a fence device"
      editHeader={(detail) => (
        <HeaderText>
          Update fence device{' '}
          <InlineMonoText fontSize="inherit">
            {detail?.fenceName}
          </InlineMonoText>{' '}
          parameters
        </HeaderText>
      )}
      entriesUrl="/fence"
      formDialogProps={{
        common: {
          wide: true,
        },
      }}
      getAddLoading={(previous) => previous || loadingFenceTemplate}
      getEditLoading={(previous) => previous || loadingFenceTemplate}
      getDeleteErrorMessage={(children, ...rest) => ({
        ...rest,
        children: <>Failed to delete fence device(s). {children}</>,
      })}
      getDeleteHeader={(count) => `Delete ${count} fence device(s)?`}
      getDeleteSuccessMessage={() => ({
        children: <>Successfully deleted fence device(s)</>,
      })}
      listEmpty="No fence device(s) found."
      onItemClick={(base, { args, entry, tools }) => {
        const [fence] = args;

        entry.set(fence);

        tools.edit.open(true);
      }}
      renderAddForm={(tools, fences) =>
        fences &&
        fenceTemplate && (
          <FenceForm fences={fences} template={fenceTemplate} tools={tools} />
        )
      }
      renderDeleteItem={(fences, { key: uuid }) => {
        const fence = fences?.[uuid];

        return <BodyText>{fence?.fenceName}</BodyText>;
      }}
      renderEditForm={(tools, fence, fences) =>
        fences &&
        fenceTemplate && (
          <FenceForm
            fence={fence}
            fences={fences}
            template={fenceTemplate}
            tools={tools}
          />
        )
      }
      renderListItem={(uuid, fence) => {
        const {
          fenceAgent: agent,
          fenceName: name,
          fenceParameters: parameters,
        } = fence;

        return (
          <Grid columnSpacing="1em" container>
            <Grid item>
              <BodyText>{name}</BodyText>
            </Grid>
            <Grid item xs>
              <BodyText noWrap>
                {Object.entries(parameters)
                  .sort(([a], [b]) => a.localeCompare(b))
                  .reduce<React.ReactNode>((previous, parameter) => {
                    const [id, value] = parameter;

                    let current: React.ReactNode = <>{id}=&quot;</>;

                    current = REP_LABEL_PASSW.test(id) ? (
                      <>
                        {current}
                        <SensitiveText
                          wrapper="mono"
                          wrapperProps={{
                            noWrap: true,
                          }}
                        >
                          {value}
                        </SensitiveText>
                      </>
                    ) : (
                      <>
                        {current}
                        {value}
                      </>
                    );

                    return (
                      <>
                        {previous} {current}&quot;
                      </>
                    );
                  }, agent)}
              </BodyText>
            </Grid>
          </Grid>
        );
      }}
    />
  );
};

export default ManageFenceList;
