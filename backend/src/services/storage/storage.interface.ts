export interface StorageProvider {
  readonly name: string;

  saveFile(
    buffer: Buffer,
    filename: string,
    mimetype: string
  ): Promise<string>;

  deleteFile(fileUrl: string): Promise<void>;

  getFileUrl(filename: string): string;
}

