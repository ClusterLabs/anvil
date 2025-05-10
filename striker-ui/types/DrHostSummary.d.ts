type DrHostSummaryOptionalProps = {
  refreshInterval?: number;
};

type DrHostSummaryProps = DrHostSummaryOptionalProps & {
  host: Pick<APIHostDetail, 'short' | 'uuid'>;
};
