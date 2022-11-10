import call from './call';
import { sanitizeSQLParam } from './sanitizeSQLParam';

type MapToReturnType = {
  boolean: boolean;
  number: number;
  string: string;
  'string[]': string[];
};

type MapToReturnFunction = {
  [ReturnTypeName in keyof MapToReturnType]: (
    value: unknown,
    modifier: (unmodified: unknown) => string,
  ) => MapToReturnType[ReturnTypeName];
};

type ModifierFunction = (unmodified: string) => string;

type MapToModifierFunction = {
  none: undefined;
  sql: ModifierFunction;
};

const MAP_TO_MODIFIER_FUNCTION: MapToModifierFunction = {
  none: undefined,
  sql: sanitizeSQLParam,
};

const MAP_TO_RETURN_FUNCTION: MapToReturnFunction = {
  boolean: (value) => value !== undefined,
  number: (value) => parseFloat(String(value)) || 0,
  string: (value, mod) => (value ? mod(value) : ''),
  'string[]': (value, mod) => {
    let result: string[] = [];

    if (value instanceof Array) {
      result = value.reduce<string[]>((reduceContainer, element) => {
        if (element) {
          reduceContainer.push(mod(element));
        }

        return reduceContainer;
      }, []);
    } else if (value) {
      result = mod(value).split(/[,;]/);
    }

    return result;
  },
};

export const sanitize = <ReturnTypeName extends keyof MapToReturnType>(
  value: unknown,
  returnType: ReturnTypeName,
  {
    modifierType = 'none',
    modifier = MAP_TO_MODIFIER_FUNCTION[modifierType],
  }: {
    modifier?: ModifierFunction;
    modifierType?: keyof MapToModifierFunction;
  } = {},
): MapToReturnType[ReturnTypeName] =>
  MAP_TO_RETURN_FUNCTION[returnType](value, (unmodified: unknown) => {
    const input = String(unmodified);

    return call<string>(modifier, {
      notCallableReturn: input,
      parameters: [input],
    });
  }) as MapToReturnType[ReturnTypeName];
