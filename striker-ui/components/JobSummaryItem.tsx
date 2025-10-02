import FlexBox from './FlexBox';
import PieProgress from './PieProgress';
import { BodyText } from './Text';
import { ago, now } from '../lib/time';

type JobSummaryItemProps = {
  job: APIJobOverview;
};

const JobSummaryItem: React.FC<JobSummaryItemProps> = (props) => {
  const { job } = props;

  const nao = now();

  const { host, name, progress, started, title } = job;

  const label = title || name;

  let status: string;

  if (started) {
    status = `Started ~${ago(nao - started)} ago on ${host.shortName}.`;
  } else {
    status = `Queued on ${host.shortName}`;
  }

  return (
    <FlexBox fullWidth spacing=".2em">
      <FlexBox row spacing=".5em">
        <PieProgress
          error={Boolean(job.error.count)}
          slotProps={{
            pie: {
              sx: {
                flexShrink: 0,
              },
            },
          }}
          value={progress}
        />
        <BodyText noWrap>{label}</BodyText>
      </FlexBox>
      <BodyText noWrap>{status}</BodyText>
    </FlexBox>
  );
};

export default JobSummaryItem;
