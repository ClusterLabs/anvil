type EditFenceInputGroupOptionalProps = {
  fenceTemplate?: APIFenceTemplate;
  loading?: boolean;
};

type EditFenceInputGroupProps = EditFenceInputGroupOptionalProps &
  Required<
    Pick<
      CommonFenceInputGroupProps,
      'fenceId' | 'previousFenceName' | 'previousFenceParameters'
    >
  >;
