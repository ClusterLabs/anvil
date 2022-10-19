import { sanitizeSQLParam } from './sanitizeSQLParam';

type MapToReturnType = {
  boolean: boolean;
  number: number;
  string: string;
  'string[]': string[];
};

type MapToReturnFunction = {
  [ReturnTypeName in keyof MapToReturnType]: (
    qs: unknown,
    modSQL: (value: string) => string,
  ) => MapToReturnType[ReturnTypeName];
};

const MAP_TO_RETURN_FUNCTION: MapToReturnFunction = {
  boolean: (qs) => qs !== undefined,
  number: (qs) => parseFloat(String(qs)) || 0,
  string: (qs, modSQL) => (qs ? modSQL(String(qs)) : ''),
  'string[]': (qs, modSQL) => {
    let result: string[] = [];

    if (qs instanceof Array) {
      result = qs.reduce<string[]>((reduceContainer, element) => {
        if (element) {
          reduceContainer.push(modSQL(String(element)));
        }

        return reduceContainer;
      }, []);
    } else if (qs) {
      result = modSQL(String(qs)).split(/[,;]/);
    }

    return result;
  },
};

export const sanitizeQS = <ReturnTypeName extends keyof MapToReturnType>(
  qs: unknown,
  {
    isForSQL = false,
    returnType = 'string',
  }: { isForSQL?: boolean; returnType?: ReturnTypeName | 'string' } = {},
): MapToReturnType[ReturnTypeName] =>
  MAP_TO_RETURN_FUNCTION[returnType](
    qs,
    isForSQL ? sanitizeSQLParam : (value: string) => value,
  ) as MapToReturnType[ReturnTypeName];
