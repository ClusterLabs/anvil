const call = <T = unknown>(
  toCall: unknown,
  { parameters = [], notCallableReturn }: CallOptions = {},
) =>
  (typeof toCall === 'function'
    ? toCall(...parameters)
    : notCallableReturn) as T;

export default call;
