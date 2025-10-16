import { Document, Schema, Types, model } from 'mongoose';

export interface IFileUpload extends Document {
  _id: Types.ObjectId;
  originalName: string;
  filename: string;
  mimetype: string;
  size: number;
  path: string;
  url: string;
  thumbnail?: string;
  uploadedBy: Types.ObjectId;
  uploadType: 'message' | 'profile' | 'chat_background' | 'document';
  metadata: {
    duration?: number; // For audio/video files
    dimensions?: {
      width: number;
      height: number;
    }; // For images/videos
    checksum?: string; // For file integrity verification
    encoding?: string;
  };
  isPublic: boolean;
  expiresAt?: Date;
  downloadCount: number;
  lastDownloaded?: Date;
  virus_scan?: {
    status: 'pending' | 'clean' | 'infected' | 'error';
    scannedAt?: Date;
    details?: string;
  };
  createdAt: Date;
  updatedAt: Date;
}

const fileUploadSchema = new Schema<IFileUpload>({
  originalName: {
    type: String,
    required: true,
    maxlength: 255
  },
  filename: {
    type: String,
    required: true,
    unique: true
  },
  mimetype: {
    type: String,
    required: true
  },
  size: {
    type: Number,
    required: true,
    max: 100 * 1024 * 1024 // 100MB limit
  },
  path: {
    type: String,
    required: true
  },
  url: {
    type: String,
    required: true
  },
  thumbnail: {
    type: String
  },
  uploadedBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  uploadType: {
    type: String,
    enum: ['message', 'profile', 'chat_background', 'document'],
    required: true
  },
  metadata: {
    duration: Number,
    dimensions: {
      width: Number,
      height: Number
    },
    checksum: String,
    encoding: String
  },
  isPublic: {
    type: Boolean,
    default: false
  },
  expiresAt: {
    type: Date,
    index: { expireAfterSeconds: 0 }
  },
  downloadCount: {
    type: Number,
    default: 0
  },
  lastDownloaded: {
    type: Date
  },
  virus_scan: {
    status: {
      type: String,
      enum: ['pending', 'clean', 'infected', 'error'],
      default: 'pending'
    },
    scannedAt: Date,
    details: String
  }
}, {
  timestamps: true
});

// Indexes for performance
fileUploadSchema.index({ uploadedBy: 1 });
fileUploadSchema.index({ uploadType: 1 });
fileUploadSchema.index({ mimetype: 1 });
fileUploadSchema.index({ createdAt: -1 });
fileUploadSchema.index({ filename: 1 }, { unique: true });

// Method to increment download count
fileUploadSchema.methods.recordDownload = function() {
  this.downloadCount += 1;
  this.lastDownloaded = new Date();
  return this.save();
};

// Method to get file category
fileUploadSchema.methods.getFileCategory = function() {
  const mimetype = this.mimetype.toLowerCase();
  
  if (mimetype.startsWith('image/')) return 'image';
  if (mimetype.startsWith('video/')) return 'video';
  if (mimetype.startsWith('audio/')) return 'audio';
  if (mimetype.includes('pdf')) return 'pdf';
  if (mimetype.includes('word') || mimetype.includes('document')) return 'document';
  if (mimetype.includes('spreadsheet') || mimetype.includes('excel')) return 'spreadsheet';
  if (mimetype.includes('presentation') || mimetype.includes('powerpoint')) return 'presentation';
  if (mimetype.includes('text/')) return 'text';
  if (mimetype.includes('archive') || mimetype.includes('zip') || mimetype.includes('rar')) return 'archive';
  
  return 'other';
};

// Static method to get file stats
fileUploadSchema.statics.getStorageStats = function() {
  return this.aggregate([
    {
      $group: {
        _id: '$uploadType',
        totalFiles: { $sum: 1 },
        totalSize: { $sum: '$size' },
        avgSize: { $avg: '$size' }
      }
    }
  ]);
};

// Pre-save middleware to generate thumbnail URL for images
fileUploadSchema.pre('save', function(next) {
  if (this.mimetype.startsWith('image/') && !this.thumbnail) {
    // Generate thumbnail URL (implementation would depend on your storage service)
    this.thumbnail = this.url.replace(/(\.[^.]+)$/, '_thumb$1');
  }
  next();
});

export const FileUpload = model<IFileUpload>('FileUpload', fileUploadSchema);