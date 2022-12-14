const call = <T = unknown>(
  toCall: unknown,
  { parameters = [], notCallableReturn }: CallOptions = {},
): T =>
  typeof toCall === 'function' ? toCall(...parameters) : notCallableReturn;

export default call;
