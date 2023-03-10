import { PlayCircle } from '@mui/icons-material';
import { FC, useMemo, useState } from 'react';
import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import List from '../List';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';

const ManageManifestPanel: FC = () => {
  const [isEditManifests, setIsEditManifests] = useState<boolean>(false);

  const { data: manifestOverviews, isLoading: isLoadingManifestOverviews } =
    periodicFetch<APIManifestOverviewList>(`${API_BASE_URL}/manifest`, {
      refreshInterval: 60000,
    });

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditManifests}
        edit={isEditManifests}
        header
        listEmpty="No manifest(s) registered."
        listItems={manifestOverviews}
        onEdit={() => {
          setIsEditManifests((previous) => !previous);
        }}
        renderListItem={(manifestUUID, { manifestName }) => (
          <FlexBox fullWidth row>
            <IconButton disabled={isEditManifests} variant="normal">
              <PlayCircle />
            </IconButton>
            <BodyText>{manifestName}</BodyText>
          </FlexBox>
        )}
      />
    ),
    [isEditManifests, manifestOverviews],
  );

  const panelContent = useMemo(
    () => (isLoadingManifestOverviews ? <Spinner /> : listElement),
    [isLoadingManifestOverviews, listElement],
  );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText>Manage manifests</HeaderText>
      </PanelHeader>
      {panelContent}
    </Panel>
  );
};

export default ManageManifestPanel;
