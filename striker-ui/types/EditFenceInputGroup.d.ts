type EditFenceInputGroupOptionalProps = {
  fenceTemplate?: APIFenceTemplate;
  loading?: boolean;
};

type EditFenceInputGroupProps<M extends MapToInputTestID> =
  EditFenceInputGroupOptionalProps &
    Required<
      Pick<
        CommonFenceInputGroupProps,
        'fenceId' | 'previousFenceName' | 'previousFenceParameters'
      >
    > & {
      formUtils: FormUtils<M>;
    };
