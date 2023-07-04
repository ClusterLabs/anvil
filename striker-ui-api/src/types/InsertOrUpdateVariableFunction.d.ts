type VariableValue = number | string;

type VariableParams = InsertOrUpdateFunctionCommonParams & {
  update_value_only?: NumberBoolean;
  variable_default?: VariableValue;
  varaible_description?: string;
  variable_name?: string;
  variable_section?: string;
  variable_source_table?: string;
  variable_source_uuid?: string;
  variable_uuid?: string;
  variable_value?: VariableValue;
};

type InsertOrUpdateVariableFunction = (
  params: VariableParams,
) => Promise<string>;
