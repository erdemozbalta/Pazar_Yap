import fs from 'fs';
import path from 'path';
import { StorageProvider } from './storage.interface';
import { config } from '../../config';

export class LocalStorageProvider implements StorageProvider {
  readonly name = 'local';
  private uploadDir: string;

  constructor() {
    this.uploadDir = path.resolve(config.upload.dir);

    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async saveFile(buffer: Buffer, filename: string, _mimetype: string): Promise<string> {
    const filePath = path.join(this.uploadDir, filename);
    const dir = path.dirname(filePath);

    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(filePath, buffer);
    console.log(`[LocalStorage] 📁 Dosya kaydedildi: ${filePath}`);
    return `/uploads/${filename}`;
  }

  async deleteFile(fileUrl: string): Promise<void> {
    const filename = fileUrl.replace('/uploads/', '');
    const filePath = path.join(this.uploadDir, filename);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log(`[LocalStorage] 🗑️ Dosya silindi: ${filePath}`);
    }
  }

  getFileUrl(filename: string): string {
    return `/uploads/${filename}`;
  }
}

