type MapToRouter<R extends import('express').Router> = {
  [uri: string]: MapToRouter<R> | R;
};
