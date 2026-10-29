export function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(2));
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

export function generateOrderNumber(): string {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const dateStr = `${year}${month}${day}`;
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let random = '';
  for (let i = 0; i < 6; i++) {
    random += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `PZR-${dateStr}-${random}`;
}

export function calculateCourierFee(
  baseFee: number,
  distanceKm: number,
  weightKg: number,
  distanceTiers: { minKm: number; maxKm: number; percentageIncrease: number }[],
  weightTiers: { minKg: number; maxKg: number; percentageIncrease: number }[]
): number {

  let distanceMultiplier = 1;
  const sortedDistanceTiers = [...distanceTiers].sort((a, b) => a.minKm - b.minKm);
  for (const tier of sortedDistanceTiers) {
    if (distanceKm >= tier.minKm && distanceKm < tier.maxKm) {
      distanceMultiplier = 1 + tier.percentageIncrease / 100;
      break;
    }
  }

  if (distanceMultiplier === 1 && sortedDistanceTiers.length > 0) {
    const lastTier = sortedDistanceTiers[sortedDistanceTiers.length - 1];
    if (distanceKm >= lastTier.maxKm) {
      distanceMultiplier = 1 + lastTier.percentageIncrease / 100;
    }
  }

  let weightMultiplier = 1;
  const sortedWeightTiers = [...weightTiers].sort((a, b) => a.minKg - b.minKg);
  for (const tier of sortedWeightTiers) {
    if (weightKg >= tier.minKg && weightKg < tier.maxKg) {
      weightMultiplier = 1 + tier.percentageIncrease / 100;
      break;
    }
  }
  if (weightMultiplier === 1 && sortedWeightTiers.length > 0) {
    const lastTier = sortedWeightTiers[sortedWeightTiers.length - 1];
    if (weightKg >= lastTier.maxKg) {
      weightMultiplier = 1 + lastTier.percentageIncrease / 100;
    }
  }

  const totalFee = baseFee * distanceMultiplier * weightMultiplier;
  return parseFloat(totalFee.toFixed(2));
}

import { getStorageProvider } from '../services/storage';
import { v4 as uuidv4 } from 'uuid';

export async function processBase64Image(base64Str?: string | null, folderName: string = 'markets'): Promise<string | null | undefined> {
  if (!base64Str) return base64Str;
  if (!base64Str.startsWith('data:image/')) return base64Str;

  try {
    const matches = base64Str.match(/^data:image\/([a-zA-Z0-9+.=]+);base64,(.+)$/);
    if (!matches || matches.length !== 3) return base64Str;

    const mime = matches[1];
    const ext = mime === 'jpeg' ? 'jpg' : mime;
    const buffer = Buffer.from(matches[2], 'base64');
    const storage = getStorageProvider();
    const filename = `${folderName}/${uuidv4()}.${ext}`;
    const fileUrl = await storage.saveFile(buffer, filename, `image/${mime}`);
    return fileUrl;
  } catch (err) {
    console.error('Base64 image conversion error:', err);
    return base64Str;
  }
}

