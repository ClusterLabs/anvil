type ExtendableEventHandler<T> = (
  toolbox: { handlers: { base?: T; origin?: T } },
  ...rest: Parameters<T>
) => ReturnType<T>;
