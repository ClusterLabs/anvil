import MuiBox from '@mui/material/Box';

import { ProgressBar } from '../Bars';
import FlexBox from '../FlexBox';
import { BodyText } from '../Text';

const UploadFileProgress: React.FC<UploadFileProgressProps> = (props) => {
  const { uploads } = props;

  return (
    <FlexBox columnSpacing=".2em">
      {Object.values(uploads).map(({ name, progress, uuid }) => (
        <MuiBox
          key={`upload-${uuid}`}
          sx={{
            alignItems: { md: 'center' },
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },

            '& > :first-child': {
              minWidth: 100,
              overflow: 'hidden',
              overflowWrap: 'normal',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
              width: { xs: '100%', md: 200 },
              wordBreak: 'keep-all',
            },

            '& > :last-child': { flexGrow: 1 },
          }}
        >
          <BodyText>{name}</BodyText>
          <ProgressBar progressPercentage={progress} />
        </MuiBox>
      ))}
    </FlexBox>
  );
};

export default UploadFileProgress;
