type FileInfoChangeHandler = (
  inputValues: Partial<FileDetailMetadata> | Partial<FileLocation>,
  options?: { fileLocationIndex?: number },
) => void;
