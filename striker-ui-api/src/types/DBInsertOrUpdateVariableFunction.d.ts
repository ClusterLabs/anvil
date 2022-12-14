type DBVariableParams = DBInsertOrUpdateFunctionCommonParams & {
  update_value_only?: 0 | 1;
  variable_default?: string;
  varaible_description?: string;
  variable_name?: string;
  variable_section?: string;
  variable_source_table?: string;
  variable_source_uuid?: string;
  variable_uuid?: string;
  variable_value?: number | string;
};

type DBInsertOrUpdateVariableOptions = DBInsertOrUpdateFunctionCommonOptions;

type DBInsertOrUpdateVariableFunction = (
  subParams: DBVariableParams,
  options?: DBInsertOrUpdateVariableOptions,
) => string;
