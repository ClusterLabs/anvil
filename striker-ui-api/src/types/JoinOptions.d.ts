type JoinOptions = {
  beforeReturn?: (toReturn?: string) => string;
  elementWrapper?: string;
  onEach?: (element: string) => string;
  separator?: string;
};
