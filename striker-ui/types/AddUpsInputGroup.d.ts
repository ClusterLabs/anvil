type AddUpsInputGroupOptionalProps = {
  loading?: boolean;
  previous?: CommonUpsInputGroupProps['previous'] & { upsTypeId?: string };
  upsTemplate?: APIUpsTemplate;
};

type AddUpsInputGroupProps = AddUpsInputGroupOptionalProps;
