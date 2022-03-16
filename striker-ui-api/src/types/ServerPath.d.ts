type ServerPathSelf = {
  self?: string;
};

type ServerPath = {
  [segment: string]: ServerPath;
} & ServerPathSelf;

type FilledServerPath = {
  [segment: string]: FilledServerPath;
} & Required<ServerPathSelf>;

type ReadonlyServerPath = Readonly<FilledServerPath>;
