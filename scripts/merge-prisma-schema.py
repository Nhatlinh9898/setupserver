#!/usr/bin/env python3
"""
Script để merge Prisma schema có sẵn với data storage models
"""

import os
import re
import sys
from pathlib import Path

# Data storage models để thêm
DATA_STORAGE_MODELS = """

// ============================================
// DATA STORAGE MODELS - Auto-generated
// ============================================

model StorageDisk {
  id              String   @id @default(cuid())
  encryptedId     String   @unique
  name            String   @unique
  mountPoint      String
  devicePath      String
  diskType        String
  totalCapacity   BigInt
  usedCapacity    BigInt   @default(0)
  availableCapacity BigInt
  isPrimary       Boolean  @default(false)
  isActive        Boolean  @default(true)
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}

model DataItem {
  id              String   @id @default(cuid())
  encryptedId     String   @unique
  title           String
  storagePath     String
  fileSize        BigInt   @default(0)
  compressedSize  BigInt   @default(0)
  categoryId      String?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}

model DataCategory {
  id            String   @id @default(cuid())
  encryptedId   String   @unique
  name          String   @unique
  description   String?
  parentId      String?
  level         Int      @default(0)
  isActive      Boolean  @default(true)
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}

model DataProcessingTask {
  id              String   @id @default(cuid())
  encryptedId     String   @unique
  taskType        String
  inputPath       String
  outputPath      String?
  status          String   @default("PENDING")
  progress        Float    @default(0)
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}
"""

def merge_schema(schema_path: str, strategy: str = "extend"):
    """
    Merge data storage models vào schema có sẵn
    
    Args:
        schema_path: Đường dẫn đến file schema.prisma
        strategy: 'extend' hoặc 'replace'
    """
    schema_file = Path(schema_path)
    
    if not schema_file.exists():
        print(f"Error: Schema file not found: {schema_path}")
        return False
    
    # Backup original schema
    backup_path = schema_file.with_suffix('.prisma.backup')
    with open(schema_file, 'r') as f:
        original_content = f.read()
    
    with open(backup_path, 'w') as f:
        f.write(original_content)
    
    print(f"Backup created: {backup_path}")
    
    if strategy == "extend":
        # Check if models already exist
        if "model StorageDisk" in original_content:
            print("Data storage models already exist in schema")
            return True
        
        # Append models to end
        with open(schema_file, 'a') as f:
            f.write(DATA_STORAGE_MODELS)
        
        print(f"Data storage models appended to {schema_path}")
        return True
    
    elif strategy == "replace":
        # Replace entire schema (not recommended)
        with open(schema_file, 'w') as f:
            f.write(DATA_STORAGE_MODELS)
        
        print(f"Schema replaced with data storage models")
        return True
    
    return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python merge-prisma-schema.py <schema_path> [strategy]")
        print("  schema_path: Path to prisma/schema.prisma")
        print("  strategy: extend (default) or replace")
        sys.exit(1)
    
    schema_path = sys.argv[1]
    strategy = sys.argv[2] if len(sys.argv) > 2 else "extend"
    
    success = merge_schema(schema_path, strategy)
    
    if success:
        print("Schema merge completed successfully")
        print("Run: npx prisma generate")
        print("Run: npx prisma migrate deploy")
        sys.exit(0)
    else:
        print("Schema merge failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
