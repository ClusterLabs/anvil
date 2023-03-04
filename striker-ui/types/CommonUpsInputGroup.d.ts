type CommonUpsInputGroupOptionalProps = {
  previous?: {
    upsIPAddress?: string;
    upsName?: string;
  };
};

type CommonUpsInputGroupProps<M extends MapToInputTestID> =
  CommonUpsInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };
