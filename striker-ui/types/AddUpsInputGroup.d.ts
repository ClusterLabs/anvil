type AddUpsInputGroupOptionalProps = {
  loading?: boolean;
  previous?: CommonUpsInputGroupOptionalProps['previous'] & {
    upsTypeId?: string;
  };
  upsTemplate: APIUpsTemplate;
};

type AddUpsInputGroupProps<M extends MapToInputTestID> =
  AddUpsInputGroupOptionalProps &
    Pick<CommonUpsInputGroupProps<M>, 'formUtils'>;
