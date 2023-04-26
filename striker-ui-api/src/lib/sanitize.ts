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
    fallback?: MapToReturnType[ReturnTypeName],
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
  number: (value, mod, fallback = 0) => parseFloat(String(value)) || fallback,
  string: (value, mod, fallback = '') => (value ? mod(value) : fallback),
  'string[]': (value, mod, fallback = []) => {
    let result: string[] = fallback;

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
    fallback,
    modifierType = 'none',
    modifier = MAP_TO_MODIFIER_FUNCTION[modifierType],
  }: {
    fallback?: MapToReturnType[ReturnTypeName];
    modifier?: ModifierFunction;
    modifierType?: keyof MapToModifierFunction;
  } = {},
): MapToReturnType[ReturnTypeName] =>
  MAP_TO_RETURN_FUNCTION[returnType](
    value,
    (unmodified: unknown) => {
      const input = String(unmodified);

      return call<string>(modifier, {
        notCallableReturn: input,
        parameters: [input],
      });
    },
    fallback,
  ) as MapToReturnType[ReturnTypeName];
