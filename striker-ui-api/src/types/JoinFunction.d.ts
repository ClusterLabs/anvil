type JoinOptions = {
  beforeReturn?: (toReturn: string) => string;
  elementWrapper?: string;
  fallback?: string;
  onEach?: (element: string) => string;
  separator?: string;
};

type JoinFunction = (
  elements: string[] | string | undefined,
  options?: JoinOptions,
) => string;
