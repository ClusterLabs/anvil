type JobDetailOptionalProps = {
  refreshInterval?: number;
};

type JobDetailProps = JobDetailOptionalProps & {
  uuid: string;
};
