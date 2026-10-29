import { StorageProvider } from './storage.interface';
import { LocalStorageProvider } from './local.provider';

let storageProvider: StorageProvider | null = null;

export function getStorageProvider(): StorageProvider {
  if (!storageProvider) {
    storageProvider = new LocalStorageProvider();
    console.log(`[Storage] Depolama sağlayıcısı başlatıldı: ${storageProvider.name}`);
  }
  return storageProvider;
}

export * from './storage.interface';

