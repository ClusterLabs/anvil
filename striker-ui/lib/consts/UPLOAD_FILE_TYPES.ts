export const UPLOAD_FILE_TYPES_ARRAY: ReadonlyArray<
  [UploadFileTypes, [string, string]]
> = [
  ['iso', ['application/x-cd-image', 'ISO (optical disc)']],
  ['other', ['text/plain', 'Other file type']],
  ['script', ['text/plain', 'Script (program)']],
];
export const UPLOAD_FILE_TYPES: ReadonlyMap<
  UploadFileTypes,
  [string, string]
> = new Map(UPLOAD_FILE_TYPES_ARRAY);
