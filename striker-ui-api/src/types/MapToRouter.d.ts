type MapToRouter = {
  [uri: string]: MapToRouter | import('express').Router;
};
