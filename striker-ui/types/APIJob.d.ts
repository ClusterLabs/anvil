/**
 * @prop started - EPOCH seconds that specify when the job started.
 */
type APIJobOverview = {
  host: {
    name: string;
    shortName: string;
    uuid: string;
  };
  modified: number;
  name: string;
  progress: number;
  started: number;
  title: string;
  uuid: string;
};

type APIJobOverviewList = Record<string, APIJobOverview>;

type APIJobData = {
  name: string;
  value: string;
};

type APIJobStatus = {
  value: string;
};

type APIJobDetail = APIJobOverview & {
  command: string;
  data: Record<string, APIJobData>;
  description: string;
  pid: number;
  status: Record<string, APIJobStatus>;
  updated: number;
};
